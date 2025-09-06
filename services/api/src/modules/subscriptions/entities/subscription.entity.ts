import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'customer_id' })
  customerId: number;

  @Column({ name: 'plan_id' })
  planId: number;

  @Column({ unique: true })
  username: string;

  @Column()
  status: string;
}
