import { STATUS_STYLES } from "@/lib/constants";
import type { Status } from "@/types";
import { cn } from "@/lib/utils";

export function Badge({ status, small }: { status: Status; small?: boolean }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full font-semibold whitespace-nowrap",
        small ? "text-[11px] px-2.5 py-[3px]" : "text-xs px-3 py-[5px]",
        STATUS_STYLES[status]
      )}
    >
      <span className="h-[7px] w-[7px] rounded-full bg-current" />
      {status}
    </span>
  );
}
