import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('service_plans')
export class ServicePlan {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column({ unique: true })
  code: string;

  @Column()
  type: string;

  @Column({ name: 'monthly_fee', type: 'decimal', precision: 10, scale: 2 })
  monthlyFee: number;
}
