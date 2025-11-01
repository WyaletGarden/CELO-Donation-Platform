import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

// Error boundary wrapper
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }

  componentDidCatch(error, errorInfo) {
    console.error('React Error:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '2rem', textAlign: 'center', color: '#333' }}>
          <h1>⚠️ Đã xảy ra lỗi</h1>
          <p>{this.state.error?.message || 'Lỗi không xác định'}</p>
          <button onClick={() => window.location.reload()}>Reload Page</button>
          <details style={{ marginTop: '1rem', textAlign: 'left' }}>
            <summary>Chi tiết lỗi</summary>
            <pre style={{ background: '#f5f5f5', padding: '1rem', overflow: 'auto' }}>
              {this.state.error?.stack}
            </pre>
          </details>
        </div>
      )
    }

    return this.props.children
  }
}

try {
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <ErrorBoundary>
        <App />
      </ErrorBoundary>
    </React.StrictMode>,
  )
} catch (error) {
  console.error('Fatal Error:', error)
  document.getElementById('root').innerHTML = `
    <div style="padding: 2rem; text-align: center;">
      <h1>⚠️ Lỗi khởi động ứng dụng</h1>
      <p>${error.message}</p>
      <p>Vui lòng kiểm tra console để biết thêm chi tiết.</p>
    </div>
  `
}
