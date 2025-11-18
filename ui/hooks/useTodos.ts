import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { todoApi, Todo, TodoRequest } from "@/lib/api";

export const useTodos = (completed?: boolean) => {
  return useQuery({
    queryKey: ["todos", completed],
    queryFn: async () => {
      const response =
        completed !== undefined
          ? await todoApi.getTodosByStatus(completed)
          : await todoApi.getAllTodos();
      return response.data.data || [];
    },
  });
};

export const useTodo = (id: string) => {
  return useQuery({
    queryKey: ["todo", id],
    queryFn: async () => {
      const response = await todoApi.getTodoById(id);
      return response.data.data;
    },
    enabled: !!id,
  });
};

export const useCreateTodo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (todo: TodoRequest) => todoApi.createTodo(todo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["todos"] });
    },
  });
};

export const useUpdateTodo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, todo }: { id: string; todo: TodoRequest }) =>
      todoApi.updateTodo(id, todo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["todos"] });
    },
  });
};

export const useDeleteTodo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => todoApi.deleteTodo(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["todos"] });
    },
  });
};
