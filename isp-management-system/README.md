# ISP Management System

A comprehensive Internet Service Provider (ISP) management system built with Django REST Framework and React. This system provides complete management of customer billing, RADIUS authentication, network monitoring, ticketing, and sales operations.

## 🚀 Features

### Core Modules

#### 1. **Customer Management**
- Customer registration and profile management
- Account status tracking (Active, Suspended, Terminated)
- Customer search and filtering
- Detailed customer information and history

#### 2. **Billing & Invoicing**
- Service plan management
- Automated monthly billing
- Invoice generation and management
- Payment tracking and history
- Usage-based billing support
- Multiple payment methods support

#### 3. **RADIUS Integration**
- FreeRADIUS integration for authentication
- Real-time online user monitoring
- Bandwidth management and rate limiting
- Session tracking and accounting
- NAS device management

#### 4. **Ticketing System**
- Multi-category support ticket system
- Priority-based ticket management
- SLA tracking and alerts
- Ticket templates for common issues
- File attachments support
- Internal notes and customer communication

#### 5. **Sales & CRM**
- Lead management and tracking
- Quote/Proposal generation
- Sales pipeline visualization
- Commission tracking
- Sales targets and performance monitoring

#### 6. **Network Operations Center (NOC)**
- Real-time network device monitoring
- Network topology visualization
- Alert management system
- Performance metrics and graphs
- Maintenance window scheduling

#### 7. **Admin Panel**
- User and role management
- System configuration
- Activity logs
- Report generation

## 🛠️ Technology Stack

### Backend
- **Framework**: Django 4.2.11 + Django REST Framework
- **Database**: PostgreSQL
- **Cache**: Redis
- **Task Queue**: Celery
- **RADIUS**: FreeRADIUS 3.0
- **Authentication**: JWT (djangorestframework-simplejwt)

### Frontend
- **Framework**: React 18.2
- **UI Library**: Material-UI (MUI) v5
- **State Management**: Redux Toolkit
- **Routing**: React Router v6
- **Charts**: Chart.js with react-chartjs-2
- **HTTP Client**: Axios
- **Data Fetching**: React Query

## 📋 Prerequisites

- Ubuntu 22.04 LTS (Jammy)
- Python 3.10+
- Node.js 16+
- PostgreSQL 14+
- Redis Server
- FreeRADIUS 3.0

## 🔧 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/isp-management-system.git
cd isp-management-system
```

### 2. Database Setup

```bash
# Run the database setup script
chmod +x scripts/setup_database.sh
./scripts/setup_database.sh

# This will create:
# - PostgreSQL database: isp_management
# - Database user: isp_user
# - Redis configuration
```

### 3. Backend Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with your database credentials

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Run development server
python manage.py runserver
```

### 4. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# Edit .env to set API URL

# Start development server
npm start
```

### 5. FreeRADIUS Setup (Optional)

```bash
# Run the FreeRADIUS installation script
chmod +x scripts/install/install_freeradius.sh
sudo ./scripts/install/install_freeradius.sh
```

## 🚀 Running the Application

### Development Mode

1. **Start Backend Services**:
```bash
# Terminal 1: Django server
cd backend
source venv/bin/activate
python manage.py runserver

# Terminal 2: Celery worker
cd backend
source venv/bin/activate
celery -A core worker -l info

# Terminal 3: Celery beat
cd backend
source venv/bin/activate
celery -A core beat -l info
```

2. **Start Frontend**:
```bash
cd frontend
npm start
```

3. **Access the Application**:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/api
- Django Admin: http://localhost:8000/admin

### Production Deployment

For production deployment, use:
- **Backend**: Gunicorn with Nginx
- **Frontend**: Build and serve with Nginx
- **Process Manager**: Supervisor or systemd
- **SSL**: Let's Encrypt

## 📱 Default Login Credentials

### Demo Accounts
- **Admin**: admin@isp-demo.com / admin123
- **Staff**: staff@isp-demo.com / staff123
- **Customer**: customer@isp-demo.com / customer123

## 🏗️ Project Structure

```
isp-management-system/
├── backend/
│   ├── accounts/          # User management
│   ├── billing/           # Billing and invoicing
│   ├── core/              # Project settings
│   ├── noc/               # Network operations
│   ├── radius_integration/# RADIUS integration
│   ├── sales/             # Sales and CRM
│   ├── tickets/           # Support tickets
│   └── manage.py
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/    # Reusable components
│   │   ├── pages/         # Page components
│   │   ├── services/      # API services
│   │   ├── store/         # Redux store
│   │   └── App.js
│   └── package.json
├── database/
│   └── migrations/
├── scripts/
│   ├── install/           # Installation scripts
│   └── setup_database.sh
└── docs/
```

## 🔌 API Documentation

The API documentation is available at:
- Swagger UI: http://localhost:8000/api/docs/
- ReDoc: http://localhost:8000/api/redoc/

### Main API Endpoints

- **Authentication**: `/api/auth/`
- **Customers**: `/api/accounts/customers/`
- **Billing**: `/api/billing/`
- **Tickets**: `/api/tickets/`
- **Sales**: `/api/sales/`
- **NOC**: `/api/noc/`
- **RADIUS**: `/api/radius/`

## 🧪 Testing

### Backend Tests
```bash
cd backend
python manage.py test
```

### Frontend Tests
```bash
cd frontend
npm test
```

## 🔒 Security Features

- JWT-based authentication
- Role-based access control (RBAC)
- API rate limiting
- CORS protection
- SQL injection prevention
- XSS protection
- CSRF protection
- Secure password hashing

## 📊 Monitoring

The system includes built-in monitoring for:
- System performance metrics
- API response times
- Error tracking
- User activity logs
- Network device status
- Service availability

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Email: support@isp-management.com
- Documentation: [docs.isp-management.com](https://docs.isp-management.com)

## 🙏 Acknowledgments

- Django Software Foundation
- React Team at Meta
- MUI Team
- FreeRADIUS Project
- All contributors and testers

---

**Note**: This is a comprehensive ISP management solution designed for Ubuntu 22.04 LTS. Make sure to follow security best practices when deploying to production.