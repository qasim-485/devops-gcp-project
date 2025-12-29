import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

function App() {
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState({});
  const [newTask, setNewTask] = useState({
    title: '',
    description: '',
    priority: 'medium'
  });
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTasks();
    fetchStats();
  }, []);

  const fetchTasks = async () => {
    try {
      const response = await axios.get(`${API_URL}/tasks`);
      setTasks(response.data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching tasks:', error);
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_URL}/stats`);
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    }
  };

  const addTask = async (e) => {
    e.preventDefault();
    if (!newTask.title.trim()) return;

    try {
      await axios.post(`${API_URL}/tasks`, newTask);
      setNewTask({ title: '', description: '', priority: 'medium' });
      fetchTasks();
      fetchStats();
    } catch (error) {
      console.error('Error adding task:', error);
    }
  };

  const updateTaskStatus = async (id, status) => {
    try {
      await axios.put(`${API_URL}/tasks/${id}`, { status });
      fetchTasks();
      fetchStats();
    } catch (error) {
      console.error('Error updating task:', error);
    }
  };

  const deleteTask = async (id) => {
    try {
      await axios.delete(`${API_URL}/tasks/${id}`);
      fetchTasks();
      fetchStats();
    } catch (error) {
      console.error('Error deleting task:', error);
    }
  };

  const filteredTasks = tasks.filter(task => {
    if (filter === 'all') return true;
    return task.status === filter;
  });

  return (
    <div className="App">
      <header className="app-header">
        <h1>📝 Task Manager Pro</h1>
        <p>Manage your tasks efficiently with real-time updates</p>
      </header>

      <div className="stats-container">
        <div className="stat-card">
          <h3>{stats.total || 0}</h3>
          <p>Total Tasks</p>
        </div>
        <div className="stat-card pending">
          <h3>{stats.pending || 0}</h3>
          <p>Pending</p>
        </div>
        <div className="stat-card progress">
          <h3>{stats.inProgress || 0}</h3>
          <p>In Progress</p>
        </div>
        <div className="stat-card completed">
          <h3>{stats.completed || 0}</h3>
          <p>Completed</p>
        </div>
      </div>

      <div className="main-container">
        <div className="form-section">
          <h2>Add New Task</h2>
          <form onSubmit={addTask}>
            <input
              type="text"
              placeholder="Task title..."
              value={newTask.title}
              onChange={(e) => setNewTask({...newTask, title: e.target.value})}
              required
            />
            <textarea
              placeholder="Task description (optional)..."
              value={newTask.description}
              onChange={(e) => setNewTask({...newTask, description: e.target.value})}
              rows="3"
            />
            <select 
              value={newTask.priority}
              onChange={(e) => setNewTask({...newTask, priority: e.target.value})}
            >
              <option value="low">Low Priority</option>
              <option value="medium">Medium Priority</option>
              <option value="high">High Priority</option>
            </select>
            <button type="submit">Add Task</button>
          </form>
        </div>

        <div className="tasks-section">
          <div className="filter-buttons">
            <button 
              className={filter === 'all' ? 'active' : ''} 
              onClick={() => setFilter('all')}
            >
              All
            </button>
            <button 
              className={filter === 'pending' ? 'active' : ''} 
              onClick={() => setFilter('pending')}
            >
              Pending
            </button>
            <button 
              className={filter === 'in-progress' ? 'active' : ''} 
              onClick={() => setFilter('in-progress')}
            >
              In Progress
            </button>
            <button 
              className={filter === 'completed' ? 'active' : ''} 
              onClick={() => setFilter('completed')}
            >
              Completed
            </button>
          </div>

          <div className="tasks-list">
            {loading ? (
              <p>Loading tasks...</p>
            ) : filteredTasks.length === 0 ? (
              <p className="no-tasks">No tasks found. Create your first task!</p>
            ) : (
              filteredTasks.map(task => (
                <div key={task._id} className={`task-card ${task.priority}`}>
                  <div className="task-header">
                    <h3>{task.title}</h3>
                    <span className={`priority-badge ${task.priority}`}>
                      {task.priority}
                    </span>
                  </div>
                  {task.description && <p>{task.description}</p>}
                  <div className="task-actions">
                    <select 
                      value={task.status}
                      onChange={(e) => updateTaskStatus(task._id, e.target.value)}
                      className={`status-select ${task.status}`}
                    >
                      <option value="pending">Pending</option>
                      <option value="in-progress">In Progress</option>
                      <option value="completed">Completed</option>
                    </select>
                    <button 
                      onClick={() => deleteTask(task._id)}
                      className="delete-btn"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;