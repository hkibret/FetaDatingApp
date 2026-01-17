"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const items = [
  { href: "/search", label: "Search" },
  { href: "/messages", label: "Messages" },
  { href: "/profile/1", label: "Profile" },
];

export default function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      style={{
        position: "fixed",
        left: 0,
        right: 0,
        bottom: 0,
        height: 64,
        borderTop: "1px solid #ddd",
        background: "#fff",
        display: "flex",
        justifyContent: "space-around",
        alignItems: "center",
      }}
    >
      {items.map((it) => {
        const active = pathname?.startsWith(it.href.split("/")[1] ? `/${it.href.split("/")[1]}` : it.href);
        return (
          <Link
            key={it.href}
            href={it.href}
            style={{
              textDecoration: "none",
              fontWeight: active ? 700 : 500,
            }}
          >
            {it.label}
          </Link>
        );
      })}
    </nav>
  );
}
