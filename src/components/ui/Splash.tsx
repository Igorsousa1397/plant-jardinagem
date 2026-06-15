"use client";
import { useEffect, useState } from "react";

// Splash de abertura: marca sobre fundo creme (igual ao background_color do PWA),
// entra com leve fade+scale e some sozinha. Respeita prefers-reduced-motion.
export function Splash() {
  const [leaving, setLeaving] = useState(false);
  const [gone, setGone] = useState(false);

  useEffect(() => {
    const t1 = setTimeout(() => setLeaving(true), 1500);
    const t2 = setTimeout(() => setGone(true), 2000);
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, []);

  if (gone) return null;

  return (
    <div
      aria-hidden
      className={`fixed inset-0 z-[60] grid place-items-center bg-papel transition-opacity duration-500 ${
        leaving ? "pointer-events-none opacity-0" : "opacity-100"
      }`}
      style={{
        backgroundImage:
          "radial-gradient(120% 80% at 50% -10%, rgba(124,139,106,.18), transparent 60%)",
      }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/logo.png" alt="Plant Jardinagem" className="splash-logo w-[62vw] max-w-[280px]" />
    </div>
  );
}
