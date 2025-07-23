// Example test file showing TDD approach
// This was written BEFORE the implementation!

describe('TaskManager', () => {
    let taskManager;
    
    beforeEach(() => {
        // Clean state for each test
        localStorage.clear();
        taskManager = new TaskManager();
    });
    
    describe('addTask', () => {
        it('should add a new task with description', () => {
            // Arrange
            const description = 'Buy groceries';
            
            // Act
            const task = taskManager.addTask(description);
            
            // Assert
            expect(task).toBeDefined();
            expect(task.description).toBe(description);
            expect(task.completed).toBe(false);
            expect(task.id).toBeDefined();
        });
        
        it('should throw error for empty description', () => {
            // Arrange & Act & Assert
            expect(() => taskManager.addTask('')).toThrow('Task description cannot be empty');
        });
        
        it('should persist task to storage', () => {
            // Arrange
            const description = 'Write tests';
            
            // Act
            taskManager.addTask(description);
            const tasks = taskManager.getTasks();
            
            // Assert
            expect(tasks).toHaveLength(1);
            expect(tasks[0].description).toBe(description);
        });
    });
    
    describe('completeTask', () => {
        it('should mark task as completed', () => {
            // Arrange
            const task = taskManager.addTask('Test task');
            
            // Act
            taskManager.completeTask(task.id);
            
            // Assert
            const updatedTask = taskManager.getTasks()[0];
            expect(updatedTask.completed).toBe(true);
        });
        
        it('should toggle completion status', () => {
            // Arrange
            const task = taskManager.addTask('Toggle task');
            
            // Act
            taskManager.completeTask(task.id); // complete
            taskManager.completeTask(task.id); // uncomplete
            
            // Assert
            const updatedTask = taskManager.getTasks()[0];
            expect(updatedTask.completed).toBe(false);
        });
    });
    
    describe('deleteTask', () => {
        it('should remove task from list', () => {
            // Arrange
            const task1 = taskManager.addTask('Task 1');
            const task2 = taskManager.addTask('Task 2');
            
            // Act
            taskManager.deleteTask(task1.id);
            
            // Assert
            const tasks = taskManager.getTasks();
            expect(tasks).toHaveLength(1);
            expect(tasks[0].id).toBe(task2.id);
        });
        
        it('should throw error for non-existent task', () => {
            // Arrange & Act & Assert
            expect(() => taskManager.deleteTask('fake-id')).toThrow('Task not found');
        });
    });
    
    describe('getStats', () => {
        it('should return correct statistics', () => {
            // Arrange
            taskManager.addTask('Task 1');
            const task2 = taskManager.addTask('Task 2');
            taskManager.addTask('Task 3');
            taskManager.completeTask(task2.id);
            
            // Act
            const stats = taskManager.getStats();
            
            // Assert
            expect(stats.total).toBe(3);
            expect(stats.completed).toBe(1);
            expect(stats.pending).toBe(2);
            expect(stats.completionRate).toBe(33.33);
        });
    });
});

// Note: These tests were written FIRST, before any implementation
// Following the Red-Green-Refactor cycle of TDD