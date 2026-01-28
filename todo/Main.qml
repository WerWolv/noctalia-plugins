import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  property var pluginApi: null

  Component.onCompleted: {
    if (pluginApi) {
      if (!pluginApi.pluginSettings.pages) {
        pluginApi.pluginSettings.pages = [
          {
            id: 0,
            name: "General"
          }
        ];
        pluginApi.pluginSettings.current_page_id = 0;
      }

      if (!pluginApi.pluginSettings.todos) {
        pluginApi.pluginSettings.todos = [];
        pluginApi.pluginSettings.count = 0;
        pluginApi.pluginSettings.completedCount = 0;
      }

      if (pluginApi.pluginSettings.isExpanded === undefined) {
        pluginApi.pluginSettings.isExpanded = false;
      }

      // Ensure all existing todos have a pageId and priority
      var todos = pluginApi.pluginSettings.todos;
      for (var i = 0; i < todos.length; i++) {
        if (todos[i].pageId === undefined) {
          todos[i].pageId = 0;
        }
        // Ensure priority is a string and has a valid value
        if (todos[i].priority === undefined || typeof todos[i].priority !== 'string') {
          todos[i].priority = "medium"; // Default priority
        } else {
          // Validate the priority value
          var validPriorities = ["high", "medium", "low"];
          if (validPriorities.indexOf(todos[i].priority) === -1) {
            todos[i].priority = "medium"; // Default to medium if invalid
          }
        }
      }

      // Initialize useCustomColors if not present
      if (pluginApi.pluginSettings.useCustomColors === undefined) {
        pluginApi.pluginSettings.useCustomColors = false;
      }

      // Initialize priority colors if not present
      if (!pluginApi.pluginSettings.priorityColors) {
        pluginApi.pluginSettings.priorityColors = {
          "high": Color.mError,       // High priority - red/error color
          "medium": Color.mPrimary,   // Medium priority - primary color
          "low": Color.mOnSurfaceVariant // Low priority - surface variant color
        };
      }

      pluginApi.saveSettings();
    }
  }



  IpcHandler {
    target: "plugin:todo"


    function togglePanel() {
      pluginApi.withCurrentScreen(screen => {
        pluginApi.togglePanel(screen);
      });
    }

    function addTodo(text: string, pageId: int, priority: string) {
      if (pluginApi && text) {
        var pages = pluginApi.pluginSettings.pages || [];
        var isValidPageId = false;

        for (var i = 0; i < pages.length; i++) {
          if (pages[i].id === pageId) {
            isValidPageId = true;
            break;
          }
        }

        if (!isValidPageId) {
          Logger.e("Todo", "Invalid pageId: " + pageId);
          return;
        }

        // Validate priority - default to medium if not provided
        var validPriorities = ["high", "medium", "low"];
        if (!priority || validPriorities.indexOf(priority) === -1) {
          priority = "medium"; // Default to medium if invalid or not provided
        }

        var todos = pluginApi.pluginSettings.todos || [];

        var newTodo = {
          id: Date.now(),
          text: text,
          completed: false,
          createdAt: new Date().toISOString(),
          pageId: pageId,
          priority: priority
        };

        todos.push(newTodo);

        pluginApi.pluginSettings.todos = todos;
        pluginApi.pluginSettings.count = todos.length;
        pluginApi.saveSettings();

        ToastService.showNotice(pluginApi?.tr("main.added_new_todo") + text);
      }
    }

    // Backward compatibility function
    function addTodoOld(text: string, pageId: int) {
      addTodo(text, pageId, "medium"); // Default to medium priority
    }

    function addTodoDefault(text: string) {
      addTodo(text, 0, "medium"); // Default to medium priority
    }

    function toggleTodo(id: int) {
      if (pluginApi && id >= 0) {
        var todos = pluginApi.pluginSettings.todos || [];
        var todoFound = false;

        for (var i = 0; i < todos.length; i++) {
          if (todos[i].id === id) {
            // Preserve all properties when updating
            todos[i] = {
              id: todos[i].id,
              text: todos[i].text,
              completed: !todos[i].completed,
              createdAt: todos[i].createdAt,
              pageId: todos[i].pageId,
              priority: todos[i].priority || "medium"
            };
            todoFound = true;
            break;
          }
        }

        if (todoFound) {
          pluginApi.pluginSettings.todos = todos;

          var completedCount = 0;
          for (var j = 0; j < todos.length; j++) {
            if (todos[j].completed) {
              completedCount++;
            }
          }
          pluginApi.pluginSettings.completedCount = completedCount;
          pluginApi.saveSettings();

          var action = todos.find(t => t.id === id).completed ? pluginApi?.tr("main.todo_completed") : pluginApi?.tr("main.todo_marked_incomplete");
          var message = pluginApi?.tr("main.todo_status_changed");
          ToastService.showNotice(message + action);
        } else {
          var message = pluginApi?.tr("main.todo_not_found");
          var endMessage = pluginApi?.tr("main.not_found_suffix");
          ToastService.showError(message + id + endMessage);
        }
      }
    }

    function clearCompleted() {
      if (pluginApi) {
        var todos = pluginApi.pluginSettings.todos || [];
        var activeTodos = todos.filter(todo => !todo.completed);

        pluginApi.pluginSettings.todos = activeTodos;
        pluginApi.pluginSettings.count = activeTodos.length;
        pluginApi.pluginSettings.completedCount = 0;
        pluginApi.saveSettings();

        var clearedCount = todos.length - activeTodos.length;
        var message = pluginApi?.tr("main.cleared_completed_todos");
        var suffix = pluginApi?.tr("main.completed_todos_suffix");
        ToastService.showNotice(message + clearedCount + suffix);
      }
    }

    function removeTodo(id: int) {
      if (pluginApi && id >= 0) {
        var todos = pluginApi.pluginSettings.todos || [];
        var indexToRemove = -1;

        for (var i = 0; i < todos.length; i++) {
          if (todos[i].id === id) {
            indexToRemove = i;
            Logger.i("Todo", "Found todo at index: " + i);
            break;
          }
        }

        if (indexToRemove !== -1) {
          todos.splice(indexToRemove, 1);

          pluginApi.pluginSettings.todos = todos;
          pluginApi.pluginSettings.count = todos.length;

          // Recalculate completed count after removal
          var completedCount = 0;
          for (var j = 0; j < todos.length; j++) {
            if (todos[j].completed) {
              completedCount++;
            }
          }
          pluginApi.pluginSettings.completedCount = completedCount;
          pluginApi.saveSettings();
          ToastService.showNotice(pluginApi?.tr("main.removed_todo"));
        } else {
          Logger.e("Todo", "Todo with ID " + id + " not found");
          ToastService.showError(pluginApi?.tr("main.todo_not_found") + id + pluginApi?.tr("main.not_found_suffix"));
        }
      } else {
        Logger.e("Todo", "Invalid pluginApi or ID for removeTodo");
      }
    }
  }
}
