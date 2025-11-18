"use client";

import { Button } from "@/components/ui/button";

interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
  confirmText?: string;
  cancelText?: string;
  variant?: "danger" | "default";
}

export default function ConfirmDialog({
  isOpen,
  title,
  message,
  onConfirm,
  onCancel,
  confirmText = "Confirm",
  cancelText = "Cancel",
  variant = "default",
}: ConfirmDialogProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-gray-900 bg-opacity-30 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl">
        <h3 className="text-xl font-semibold text-gray-900 mb-2">{title}</h3>
        <p className="text-gray-600 mb-6">{message}</p>

        <div className="flex gap-3 justify-end">
          <Button
            onClick={onCancel}
            variant="outline"
            className="px-4 py-2 rounded-lg"
          >
            {cancelText}
          </Button>
          <Button
            onClick={onConfirm}
            className={`px-4 py-2 rounded-lg ${
              variant === "danger"
                ? "bg-red-600 hover:bg-red-700 text-white"
                : "bg-gray-800 hover:bg-gray-900 text-white"
            }`}
          >
            {confirmText}
          </Button>
        </div>
      </div>
    </div>
  );
}
