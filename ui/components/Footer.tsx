"use client";

import HealthIndicator from "./HealthIndicator";

export default function Footer() {
  return (
    <footer className="border-t border-gray-200 bg-white py-4 sm:py-6">
      <div className="max-w-3xl mx-auto px-4">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-4">
          <div className="text-sm text-gray-500 text-center sm:text-left">
            <p>&copy; 2025 Todo App. Built with Spring Boot & Next.js</p>
            <p className="text-xs text-gray-400 mt-1">
              Developed by Xander Billa
            </p>
          </div>

          <div className="flex items-center gap-2 sm:gap-4">
            <HealthIndicator />
          </div>
        </div>

        <div className="mt-3 text-xs text-gray-400 text-center">
          <p>
            Deployed with CI/CD • Managed by Puppet • Infrastructure by
            Terraform
          </p>
        </div>
      </div>
    </footer>
  );
}
