import TodoForm from "@/components/TodoForm";
import TodoList from "@/components/TodoList";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      {/* Header */}
      <header className="py-6 sm:py-8">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-2 sm:mb-4 tracking-tight">
            Your Todo List
          </h1>
          <p className="text-base sm:text-lg md:text-xl text-gray-600 font-medium">
            Stay organized and get things done
          </p>
        </div>
      </header>

      {/* Main Content */}
      <div className="max-w-3xl mx-auto px-4 pb-6 sm:pb-8">
        <div className="space-y-4 sm:space-y-6 md:space-y-8">
          <div className="bg-white rounded-xl sm:rounded-2xl shadow-lg sm:shadow-xl p-4 sm:p-6 md:p-8">
            <TodoForm />
          </div>

          <div className="bg-white rounded-xl sm:rounded-2xl shadow-lg sm:shadow-xl p-4 sm:p-6 md:p-8">
            <TodoList />
          </div>
        </div>
      </div>

      {/* Footer */}
      <Footer />
    </div>
  );
}
