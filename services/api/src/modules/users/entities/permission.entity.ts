import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToMany,
} from 'typeorm';
import { Role } from './role.entity';

@Entity('permissions')
export class Permission {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  name: string;

  @Column()
  resource: string;

  @Column()
  action: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ManyToMany(() => Role, role => role.permissions)
  roles: Role[];

  // Helper method to format permission display name
  get displayName(): string {
    return `${this.resource}:${this.action}`;
  }

  // Helper method to check if permission matches a pattern
  matches(resource: string, action: string): boolean {
    return this.resource === resource && this.action === action;
  }
}
