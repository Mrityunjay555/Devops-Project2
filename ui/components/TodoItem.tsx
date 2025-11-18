"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { useUpdateTodo, useDeleteTodo } from "@/hooks/useTodos";
import { Todo } from "@/lib/api";
import { Trash2, Edit2, Check, X } from "lucide-react";
import ConfirmDialog from "./ConfirmDialog";

interface TodoItemProps {
  todo: Todo;
}

export default function TodoItem({ todo }: TodoItemProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [editTitle, setEditTitle] = useState(todo.title);
  const [editDescription, setEditDescription] = useState(
    todo.description || ""
  );

  const updateTodo = useUpdateTodo();
  const deleteTodo = useDeleteTodo();

  const handleToggleComplete = async () => {
    // Only allow marking as complete, not uncompleting
    if (todo.completed) return;

    try {
      await updateTodo.mutateAsync({
        id: todo.id,
        todo: {
          title: todo.title,
          description: todo.description,
          completed: true,
        },
      });
    } catch (error) {
      console.error("Failed to update todo:", error);
    }
  };

  const handleSaveEdit = async () => {
    if (!editTitle.trim()) return;

    try {
      await updateTodo.mutateAsync({
        id: todo.id,
        todo: {
          title: editTitle.trim(),
          description: editDescription.trim() || undefined,
          completed: todo.completed,
        },
      });
      setIsEditing(false);
    } catch (error) {
      console.error("Failed to update todo:", error);
    }
  };

  const handleCancelEdit = () => {
    setEditTitle(todo.title);
    setEditDescription(todo.description || "");
    setIsEditing(false);
  };

  const handleDelete = async () => {
    try {
      await deleteTodo.mutateAsync(todo.id);
      setShowDeleteDialog(false);
    } catch (error) {
      console.error("Failed to delete todo:", error);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <>
      <div
        className={`bg-gray-50 rounded-xl p-4 border-2 border-transparent hover:border-gray-200 transition-all ${
          todo.completed ? "opacity-60 bg-gray-100" : ""
        }`}
      >
        <div className="flex items-start gap-4">
          {!todo.completed && (
            <Checkbox
              checked={false}
              onCheckedChange={handleToggleComplete}
              disabled={updateTodo.isPending || todo.completed}
              className="mt-1 scale-125"
            />
          )}
          {todo.completed && (
            <div className="mt-1 w-5 h-5 bg-gray-400 rounded flex items-center justify-center">
              <Check className="h-3 w-3 text-white" />
            </div>
          )}

          <div className="flex-1 min-w-0">
            {isEditing ? (
              <div className="space-y-3">
                <Input
                  value={editTitle}
                  onChange={(e) => setEditTitle(e.target.value)}
                  placeholder="Task title..."
                  className="border-2 border-gray-200 focus:border-gray-400 rounded-lg"
                />
                <Input
                  value={editDescription}
                  onChange={(e) => setEditDescription(e.target.value)}
                  placeholder="Description (optional)..."
                  className="border-2 border-gray-200 focus:border-gray-400 rounded-lg"
                />
                <div className="flex gap-2">
                  <Button
                    size="sm"
                    onClick={handleSaveEdit}
                    disabled={!editTitle.trim() || updateTodo.isPending}
                    className="bg-green-600 hover:bg-green-700 rounded-lg"
                  >
                    <Check className="h-4 w-4" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={handleCancelEdit}
                    className="rounded-lg"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ) : (
              <div>
                <h3
                  className={`font-medium text-lg ${
                    todo.completed
                      ? "line-through text-gray-500"
                      : "text-gray-800"
                  }`}
                >
                  {todo.title}
                </h3>
                {todo.description && (
                  <p
                    className={`text-gray-600 mt-1 ${
                      todo.completed ? "line-through" : ""
                    }`}
                  >
                    {todo.description}
                  </p>
                )}
                <p className="text-xs text-gray-400 mt-3">
                  Created {formatDate(todo.createdAt)}
                </p>
              </div>
            )}
          </div>

          {!isEditing && (
            <div className="flex gap-1">
              {!todo.completed && (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setIsEditing(true)}
                  className="text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg"
                >
                  <Edit2 className="h-4 w-4" />
                </Button>
              )}
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setShowDeleteDialog(true)}
                disabled={deleteTodo.isPending}
                className="text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          )}
        </div>
      </div>

      <ConfirmDialog
        isOpen={showDeleteDialog}
        title="Delete Task"
        message="Are you sure you want to delete this task? This action cannot be undone."
        onConfirm={handleDelete}
        onCancel={() => setShowDeleteDialog(false)}
        confirmText="Delete"
        cancelText="Cancel"
        variant="danger"
      />
    </>
  );
}
