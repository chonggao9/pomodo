// 数据库版本迁移定义列表
import migration001Sql from './001_initial_schema.sql?raw';

export interface MigrationDefinition {
  version: number;
  name: string;
  sql: string;
}

export const MIGRATIONS: MigrationDefinition[] = [
  {
    version: 1,
    name: '001_initial_schema',
    sql: migration001Sql,
  },
];
