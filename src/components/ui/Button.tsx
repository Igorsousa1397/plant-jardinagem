"use client";
import { cn } from "@/lib/utils";

type Variant = "primary" | "gold" | "secondary" | "ghost" | "danger";

const styles: Record<Variant, string> = {
  primary: "bg-verde-700 text-white hover:bg-verde-800",
  gold: "bg-dourado text-[#2A2105] hover:brightness-105",
  secondary: "bg-transparent text-verde-700 ring-[1.5px] ring-inset ring-verde-400 hover:bg-verde-50",
  ghost: "bg-transparent text-verde-700 hover:bg-verde-50",
  danger: "bg-erro text-white",
};

interface Props extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  block?: boolean;
}

export function Button({ variant = "primary", block, className, ...rest }: Props) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-[10px] px-5 py-3 text-[15px] font-semibold leading-none transition",
        "focus-visible:outline focus-visible:outline-[3px] focus-visible:outline-offset-2 focus-visible:outline-verde-300",
        "disabled:cursor-not-allowed disabled:bg-surface2 disabled:text-tintaMuda",
        block && "w-full",
        styles[variant],
        className
      )}
      {...rest}
    />
  );
}
