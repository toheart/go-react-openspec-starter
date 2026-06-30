export interface SampleItem {
  id: string;
  name: string;
  summary: string;
  category: 'backend' | 'frontend' | 'workflow';
  status: 'ready' | 'in-progress' | 'done';
  updatedAt: string;
}
