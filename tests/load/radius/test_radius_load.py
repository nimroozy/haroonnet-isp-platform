#!/usr/bin/env python3
"""
HaroonNet ISP Platform - RADIUS Load Test
Tests RADIUS server performance under high load (10,000+ concurrent sessions)
"""

import asyncio
import time
import statistics
from concurrent.futures import ThreadPoolExecutor
from pyrad.client import Client
from pyrad.dictionary import Dictionary
from pyrad import packet
import logging
import json
import sys
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class RadiusLoadTester:
    def __init__(self, server_ip='localhost', auth_port=1812, acct_port=1813, secret='testing123'):
        self.server_ip = server_ip
        self.auth_port = auth_port
        self.acct_port = acct_port
        self.secret = secret.encode()
        self.dictionary = Dictionary("dictionary")

        # Test configuration
        self.concurrent_users = 10000
        self.test_duration = 300  # 5 minutes
        self.ramp_up_time = 60   # 1 minute

        # Metrics
        self.auth_success = 0
        self.auth_failure = 0
        self.auth_timeout = 0
        self.acct_success = 0
        self.acct_failure = 0
        self.response_times = []

    def create_radius_client(self):
        """Create a RADIUS client instance"""
        return Client(
            server=self.server_ip,
            authport=self.auth_port,
            acctport=self.acct_port,
            secret=self.secret,
            dict=self.dictionary
        )

    def authenticate_user(self, username, password):
        """Perform RADIUS authentication"""
        start_time = time.time()

        try:
            client = self.create_radius_client()

            # Create authentication request
            req = client.CreateAuthPacket(code=packet.AccessRequest)
            req["User-Name"] = username
            req["User-Password"] = req.PwCrypt(password)
            req["NAS-IP-Address"] = "192.168.1.1"
            req["NAS-Port"] = 1234
            req["Service-Type"] = "Framed-User"
            req["Framed-Protocol"] = "PPP"

            # Send request
            reply = client.SendPacket(req)

            response_time = time.time() - start_time
            self.response_times.append(response_time)

            if reply.code == packet.AccessAccept:
                self.auth_success += 1
                return True, response_time
            else:
                self.auth_failure += 1
                return False, response_time

        except Exception as e:
            self.auth_timeout += 1
            logger.error(f"Authentication error for {username}: {str(e)}")
            return False, time.time() - start_time

    def send_accounting(self, username, session_id, status_type):
        """Send RADIUS accounting packet"""
        start_time = time.time()

        try:
            client = self.create_radius_client()

            # Create accounting request
            req = client.CreateAcctPacket()
            req["User-Name"] = username
            req["Acct-Session-Id"] = session_id
            req["Acct-Status-Type"] = status_type
            req["NAS-IP-Address"] = "192.168.1.1"
            req["NAS-Port"] = 1234

            if status_type == "Start":
                req["Service-Type"] = "Framed-User"
                req["Framed-Protocol"] = "PPP"
                req["Framed-IP-Address"] = "10.1.1.1"
            elif status_type == "Stop":
                req["Acct-Session-Time"] = 3600
                req["Acct-Input-Octets"] = 1000000
                req["Acct-Output-Octets"] = 5000000
                req["Acct-Terminate-Cause"] = "User-Request"

            # Send request
            reply = client.SendPacket(req)

            response_time = time.time() - start_time

            if reply.code == packet.AccountingResponse:
                self.acct_success += 1
                return True, response_time
            else:
                self.acct_failure += 1
                return False, response_time

        except Exception as e:
            logger.error(f"Accounting error for {username}: {str(e)}")
            return False, time.time() - start_time

    def simulate_user_session(self, user_id):
        """Simulate a complete user session"""
        username = f"loadtest{user_id:06d}@haroonnet.com"
        password = "test123"
        session_id = f"sess_{user_id}_{int(time.time())}"

        session_metrics = {
            'username': username,
            'auth_success': False,
            'acct_start_success': False,
            'acct_stop_success': False,
            'auth_time': 0,
            'acct_start_time': 0,
            'acct_stop_time': 0,
            'total_time': 0
        }

        session_start = time.time()

        # 1. Authentication
        auth_success, auth_time = self.authenticate_user(username, password)
        session_metrics['auth_success'] = auth_success
        session_metrics['auth_time'] = auth_time

        if not auth_success:
            session_metrics['total_time'] = time.time() - session_start
            return session_metrics

        # 2. Accounting Start
        acct_start_success, acct_start_time = self.send_accounting(username, session_id, "Start")
        session_metrics['acct_start_success'] = acct_start_success
        session_metrics['acct_start_time'] = acct_start_time

        # 3. Simulate session duration (random between 60-300 seconds for load test)
        import random
        session_duration = random.randint(10, 30)  # Shorter for load test
        time.sleep(session_duration)

        # 4. Accounting Stop
        acct_stop_success, acct_stop_time = self.send_accounting(username, session_id, "Stop")
        session_metrics['acct_stop_success'] = acct_stop_success
        session_metrics['acct_stop_time'] = acct_stop_time

        session_metrics['total_time'] = time.time() - session_start

        return session_metrics

    def run_concurrent_load_test(self):
        """Run concurrent load test with multiple users"""
        logger.info(f"Starting RADIUS load test with {self.concurrent_users} concurrent users")

        start_time = time.time()
        session_results = []

        # Calculate users per second for ramp-up
        users_per_second = self.concurrent_users / self.ramp_up_time

        with ThreadPoolExecutor(max_workers=min(self.concurrent_users, 500)) as executor:
            futures = []

            for user_id in range(1, self.concurrent_users + 1):
                # Ramp-up delay
                if user_id > 1:
                    delay = (user_id - 1) / users_per_second
                    if delay > 0:
                        time.sleep(min(delay, 0.1))  # Max 100ms between users

                future = executor.submit(self.simulate_user_session, user_id)
                futures.append(future)

                # Progress logging
                if user_id % 1000 == 0:
                    logger.info(f"Started {user_id} user sessions")

            # Collect results
            logger.info("Waiting for all sessions to complete...")
            for i, future in enumerate(futures):
                try:
                    result = future.result(timeout=600)  # 10 minute timeout per session
                    session_results.append(result)

                    if (i + 1) % 1000 == 0:
                        logger.info(f"Completed {i + 1} sessions")

                except Exception as e:
                    logger.error(f"Session {i + 1} failed: {str(e)}")

        total_time = time.time() - start_time

        # Calculate metrics
        self.calculate_and_report_metrics(session_results, total_time)

    def calculate_and_report_metrics(self, session_results, total_time):
        """Calculate and report test metrics"""
        logger.info("Calculating test metrics...")

        # Basic counts
        total_sessions = len(session_results)
        successful_auths = sum(1 for s in session_results if s['auth_success'])
        successful_acct_starts = sum(1 for s in session_results if s['acct_start_success'])
        successful_acct_stops = sum(1 for s in session_results if s['acct_stop_success'])

        # Response time statistics
        auth_times = [s['auth_time'] for s in session_results if s['auth_success']]
        acct_start_times = [s['acct_start_time'] for s in session_results if s['acct_start_success']]
        acct_stop_times = [s['acct_stop_time'] for s in session_results if s['acct_stop_success']]

        # Calculate percentiles
        def calculate_percentiles(times):
            if not times:
                return {'min': 0, 'max': 0, 'avg': 0, 'p50': 0, 'p95': 0, 'p99': 0}

            return {
                'min': min(times),
                'max': max(times),
                'avg': statistics.mean(times),
                'p50': statistics.median(times),
                'p95': self.percentile(times, 95),
                'p99': self.percentile(times, 99)
            }

        auth_stats = calculate_percentiles(auth_times)
        acct_start_stats = calculate_percentiles(acct_start_times)
        acct_stop_stats = calculate_percentiles(acct_stop_times)

        # Throughput calculations
        auth_throughput = successful_auths / total_time
        acct_throughput = (successful_acct_starts + successful_acct_stops) / total_time

        # Generate report
        report = {
            'test_configuration': {
                'concurrent_users': self.concurrent_users,
                'test_duration': total_time,
                'ramp_up_time': self.ramp_up_time,
                'server_ip': self.server_ip
            },
            'session_metrics': {
                'total_sessions': total_sessions,
                'successful_authentications': successful_auths,
                'successful_acct_starts': successful_acct_starts,
                'successful_acct_stops': successful_acct_stops,
                'auth_success_rate': (successful_auths / total_sessions) * 100 if total_sessions > 0 else 0,
                'acct_success_rate': (successful_acct_starts / total_sessions) * 100 if total_sessions > 0 else 0
            },
            'performance_metrics': {
                'auth_throughput_per_second': auth_throughput,
                'acct_throughput_per_second': acct_throughput,
                'total_throughput_per_second': auth_throughput + acct_throughput
            },
            'response_time_metrics': {
                'authentication': auth_stats,
                'accounting_start': acct_start_stats,
                'accounting_stop': acct_stop_stats
            }
        }

        # Print report
        self.print_report(report)

        # Save detailed results
        self.save_results(report, session_results)

        # Check if performance criteria are met
        self.validate_performance_criteria(report)

    def percentile(self, data, p):
        """Calculate percentile"""
        data_sorted = sorted(data)
        index = (len(data_sorted) - 1) * p / 100
        lower = int(index)
        upper = lower + 1
        weight = index - lower

        if upper >= len(data_sorted):
            return data_sorted[-1]

        return data_sorted[lower] * (1 - weight) + data_sorted[upper] * weight

    def print_report(self, report):
        """Print test report"""
        print("\n" + "="*80)
        print("HAROONNET ISP PLATFORM - RADIUS LOAD TEST REPORT")
        print("="*80)

        # Test configuration
        config = report['test_configuration']
        print(f"\nTest Configuration:")
        print(f"  Concurrent Users: {config['concurrent_users']:,}")
        print(f"  Test Duration: {config['test_duration']:.1f} seconds")
        print(f"  Server: {config['server_ip']}")

        # Session metrics
        session = report['session_metrics']
        print(f"\nSession Metrics:")
        print(f"  Total Sessions: {session['total_sessions']:,}")
        print(f"  Successful Authentications: {session['successful_authentications']:,}")
        print(f"  Authentication Success Rate: {session['auth_success_rate']:.2f}%")
        print(f"  Accounting Success Rate: {session['acct_success_rate']:.2f}%")

        # Performance metrics
        perf = report['performance_metrics']
        print(f"\nPerformance Metrics:")
        print(f"  Authentication Throughput: {perf['auth_throughput_per_second']:.1f} req/sec")
        print(f"  Accounting Throughput: {perf['acct_throughput_per_second']:.1f} req/sec")
        print(f"  Total Throughput: {perf['total_throughput_per_second']:.1f} req/sec")

        # Response times
        auth = report['response_time_metrics']['authentication']
        print(f"\nAuthentication Response Times:")
        print(f"  Average: {auth['avg']*1000:.1f}ms")
        print(f"  50th percentile: {auth['p50']*1000:.1f}ms")
        print(f"  95th percentile: {auth['p95']*1000:.1f}ms")
        print(f"  99th percentile: {auth['p99']*1000:.1f}ms")
        print(f"  Max: {auth['max']*1000:.1f}ms")

        print("\n" + "="*80)

    def save_results(self, report, session_results):
        """Save detailed test results"""
        timestamp = int(time.time())

        # Save summary report
        with open(f'radius_load_test_report_{timestamp}.json', 'w') as f:
            json.dump(report, f, indent=2)

        # Save detailed session results
        with open(f'radius_load_test_sessions_{timestamp}.json', 'w') as f:
            json.dump(session_results, f, indent=2)

        logger.info(f"Results saved to radius_load_test_*_{timestamp}.json")

    def validate_performance_criteria(self, report):
        """Validate against performance criteria"""
        print(f"\nPerformance Criteria Validation:")

        criteria_met = True

        # Authentication response time < 100ms (95th percentile)
        auth_p95 = report['response_time_metrics']['authentication']['p95'] * 1000
        if auth_p95 <= 100:
            print(f"  ✓ Authentication response time: {auth_p95:.1f}ms (≤ 100ms)")
        else:
            print(f"  ✗ Authentication response time: {auth_p95:.1f}ms (> 100ms)")
            criteria_met = False

        # Success rate > 99%
        success_rate = report['session_metrics']['auth_success_rate']
        if success_rate >= 99:
            print(f"  ✓ Authentication success rate: {success_rate:.2f}% (≥ 99%)")
        else:
            print(f"  ✗ Authentication success rate: {success_rate:.2f}% (< 99%)")
            criteria_met = False

        # Throughput > 100 req/sec
        throughput = report['performance_metrics']['total_throughput_per_second']
        if throughput >= 100:
            print(f"  ✓ Total throughput: {throughput:.1f} req/sec (≥ 100 req/sec)")
        else:
            print(f"  ✗ Total throughput: {throughput:.1f} req/sec (< 100 req/sec)")
            criteria_met = False

        if criteria_met:
            print(f"\n🎉 All performance criteria met!")
            return 0
        else:
            print(f"\n❌ Some performance criteria not met!")
            return 1

def main():
    """Main test execution"""
    # Parse command line arguments
    import argparse

    parser = argparse.ArgumentParser(description='RADIUS Load Test')
    parser.add_argument('--server', default='localhost', help='RADIUS server IP')
    parser.add_argument('--users', type=int, default=1000, help='Number of concurrent users')
    parser.add_argument('--secret', default='testing123', help='RADIUS shared secret')
    parser.add_argument('--ramp-up', type=int, default=60, help='Ramp-up time in seconds')

    args = parser.parse_args()

    # Create and configure tester
    tester = RadiusLoadTester(
        server_ip=args.server,
        secret=args.secret
    )
    tester.concurrent_users = args.users
    tester.ramp_up_time = args.ramp_up

    try:
        # Run the load test
        exit_code = tester.run_concurrent_load_test()
        sys.exit(exit_code or 0)

    except KeyboardInterrupt:
        logger.info("Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Test failed: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()
