import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = '/api';

function App() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Form state
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'medium',
    status: 'pending'
  });
  
  const [editingTask, setEditingTask] = useState(null);

  useEffect(() => {
    fetchTasks();
    fetchStats();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/tasks`);
      setTasks(response.data);
      setError('');
    } catch (err) {
      setError('Failed to fetch tasks');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_URL}/stats`);
      setStats(response.data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      if (editingTask) {
        await axios.put(`${API_URL}/tasks/${editingTask._id}`, formData);
        setEditingTask(null);
      } else {
        await axios.post(`${API_URL}/tasks`, formData);
      }
      
      setFormData({
        title: '',
        description: '',
        priority: 'medium',
        status: 'pending'
      });
      
      fetchTasks();
      fetchStats();
      setError('');
    } catch (err) {
      setError(editingTask ? 'Failed to update task' : 'Failed to create task');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this task?')) return;
    
    try {
      setLoading(true);
      await axios.delete(`${API_URL}/tasks/${id}`);
      fetchTasks();
      fetchStats();
      setError('');
    } catch (err) {
      setError('Failed to delete task');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (task) => {
    setEditingTask(task);
    setFormData({
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: task.status
    });
  };

  const handleCancel = () => {
    setEditingTask(null);
    setFormData({
      title: '',
      description: '',
      priority: 'medium',
      status: 'pending'
    });
  };

  const getPriorityColor = (priority) => {
    switch(priority) {
      case 'high': return '#dc3545';
      case 'medium': return '#ffc107';
      case 'low': return '#28a745';
      default: return '#6c757d';
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'completed': return '#28a745';
      case 'in-progress': return '#17a2b8';
      case 'pending': return '#6c757d';
      default: return '#6c757d';
    }
  };

  return (
    <div className="App">
      <header className="app-header">
        <h1>🚀 Task Manager</h1>
        <p>MERN Stack DevOps Project</p>
      </header>

      {stats && (
        <div className="stats-container">
          <div className="stat-card">
            <h3>{stats.totalTasks}</h3>
            <p>Total Tasks</p>
          </div>
          <div className="stat-card">
            <h3>{stats.completedTasks}</h3>
            <p>Completed</p>
          </div>
          <div className="stat-card">
            <h3>{stats.inProgressTasks}</h3>
            <p>In Progress</p>
          </div>
          <div className="stat-card">
            <h3>{stats.pendingTasks}</h3>
            <p>Pending</p>
          </div>
        </div>
      )}

      <div className="main-container">
        <div className="form-container">
          <h2>{editingTask ? 'Edit Task' : 'Create New Task'}</h2>
          {error && <div className="error-message">{error}</div>}
          
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Title</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({...formData, title: e.target.value})}
                required
                placeholder="Enter task title"
              />
            </div>

            <div className="form-group">
              <label>Description</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({...formData, description: e.target.value})}
                required
                placeholder="Enter task description"
                rows="3"
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Priority</label>
                <select
                  value={formData.priority}
                  onChange={(e) => setFormData({...formData, priority: e.target.value})}
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>

              <div className="form-group">
                <label>Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData({...formData, status: e.target.value})}
                >
                  <option value="pending">Pending</option>
                  <option value="in-progress">In Progress</option>
                  <option value="completed">Completed</option>
                </select>
              </div>
            </div>

            <div className="button-group">
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Saving...' : editingTask ? 'Update Task' : 'Create Task'}
              </button>
              {editingTask && (
                <button type="button" className="btn btn-secondary" onClick={handleCancel}>
                  Cancel
                </button>
              )}
            </div>
          </form>
        </div>

        <div className="tasks-container">
          <h2>Tasks ({tasks.length})</h2>
          {loading && <p>Loading...</p>}
          
          {tasks.length === 0 && !loading && (
            <div className="empty-state">
              <p>No tasks yet. Create your first task!</p>
            </div>
          )}

          <div className="tasks-grid">
            {tasks.map((task) => (
              <div key={task._id} className="task-card">
                <div className="task-header">
                  <h3>{task.title}</h3>
                  <div className="task-badges">
                    <span 
                      className="badge priority-badge"
                      style={{backgroundColor: getPriorityColor(task.priority)}}
                    >
                      {task.priority}
                    </span>
                    <span 
                      className="badge status-badge"
                      style={{backgroundColor: getStatusColor(task.status)}}
                    >
                      {task.status}
                    </span>
                  </div>
                </div>
                
                <p className="task-description">{task.description}</p>
                
                <div className="task-footer">
                  <span className="task-date">
                    {new Date(task.createdAt).toLocaleDateString()}
                  </span>
                  <div className="task-actions">
                    <button 
                      className="btn-icon btn-edit"
                      onClick={() => handleEdit(task)}
                      title="Edit"
                    >
                      ✏️
                    </button>
                    <button 
                      className="btn-icon btn-delete"
                      onClick={() => handleDelete(task._id)}
                      title="Delete"
                    >
                      🗑️
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <footer className="app-footer">
        <p>DevOps GCP Project | Muhammad Saad | FYP 2024</p>
      </footer>
    </div>
  );
}

export default App;