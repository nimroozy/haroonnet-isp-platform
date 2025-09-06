import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('tickets')
export class Ticket {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'ticket_number', unique: true })
  ticketNumber: string;

  @Column({ name: 'customer_id' })
  customerId: number;

  @Column()
  subject: string;

  @Column({ type: 'text' })
  description: string;

  @Column()
  status: string;

  @Column()
  priority: string;
}
