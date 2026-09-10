// 分类数据访问仓库 (Category Repository)
import { SQLiteEngine } from '../engine';
import type { CategoryEntity } from '../types';

export class CategoryRepository {
  private engine = SQLiteEngine.getInstance();

  /** 获取所有分类 */
  public getAllCategories(): CategoryEntity[] {
    return this.engine.query<CategoryEntity>(`
      SELECT * FROM categories
      ORDER BY sort_order ASC, id ASC;
    `);
  }

  /** 创建新分类 */
  public createCategory(data: { name: string; color: string; icon?: string }): CategoryEntity {
    const id = `cat_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const countRes = this.engine.queryOne<{ count: number }>('SELECT COUNT(*) as count FROM categories;');
    const sortOrder = countRes ? Number(countRes.count) + 1 : 1;

    this.engine.run(`
      INSERT INTO categories (id, name, color, icon, sort_order)
      VALUES (?, ?, ?, ?, ?);
    `, [id, data.name, data.color, data.icon ?? null, sortOrder]);

    return {
      id,
      name: data.name,
      color: data.color,
      icon: data.icon ?? null,
      sort_order: sortOrder,
    };
  }
}
