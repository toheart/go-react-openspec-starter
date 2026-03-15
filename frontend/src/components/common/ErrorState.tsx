interface ErrorStateProps {
  message: string;
  onRetry?: () => void;
}

export function ErrorState({ message, onRetry }: ErrorStateProps) {
  return (
    <div className="state-panel state-panel-error">
      <p>Request failed: {message}</p>
      {onRetry ? (
        <button className="secondary-button" onClick={onRetry} type="button">
          Try again
        </button>
      ) : null}
    </div>
  );
}
