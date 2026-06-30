import { ErrorState } from './common/ErrorState';
import { Loading } from './common/Loading';
import { useApi } from '../hooks/useApi';
import { fetchSamples } from '../services/api';
import type { SampleItem } from '../types/sample';

function categoryClass(category: SampleItem['category']): string {
  if (category === 'backend') {
    return 'badge badge-critical';
  }

  if (category === 'frontend') {
    return 'badge badge-warning';
  }

  return 'badge badge-info';
}

export function Home() {
  const { data, error, loading, refetch } = useApi(fetchSamples);

  return (
    <main className="layout">
      <section className="hero">
        <div>
          <p className="eyebrow">Go + React skeleton</p>
          <h1>Starter sample workspace</h1>
          <p className="hero-copy">
            A reusable full-stack baseline showing Go service layering, typed frontend access,
            and OpenSpec-guided delivery.
          </p>
        </div>
        <button className="primary-button" onClick={() => void refetch()} type="button">
          Refresh
        </button>
      </section>

      {loading && <Loading />}
      {error && !loading && <ErrorState message={error.message} onRetry={() => void refetch()} />}

      {!loading && !error && (
        <section className="card-grid">
          {data?.map((sample) => (
            <article className="sample-card" key={sample.id}>
              <div className="sample-card-header">
                <span className={categoryClass(sample.category)}>{sample.category}</span>
                <span className="status-pill">{sample.status}</span>
              </div>
              <h2>{sample.name}</h2>
              <p>{sample.summary}</p>
              <time dateTime={sample.updatedAt}>
                {new Date(sample.updatedAt).toLocaleString()}
              </time>
            </article>
          ))}
        </section>
      )}
    </main>
  );
}
