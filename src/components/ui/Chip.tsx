"use client";
import { cn } from "@/lib/utils";

export function Chip({
  active,
  children,
  onClick,
}: {
  active?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "rounded-full border-[1.5px] px-3 py-2 text-[13px] font-semibold transition",
        active
          ? "border-verde-600 bg-verde-50 text-verde-700"
          : "border-linha bg-surface text-tintaMuda"
      )}
    >
      {children}
    </button>
  );
}
