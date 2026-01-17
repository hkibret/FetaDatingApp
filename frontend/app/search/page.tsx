"use client";

import { useEffect, useState } from "react";
import ProfileCard from "../../components/ProfileCard";
import { apiGet } from "../../services/api";

type Profile = {
  id: string;
  name: string;
  age?: number;
  bio?: string;
};

export default function SearchPage() {
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        // Replace with your real endpoint later
        const data = await apiGet<Profile[]>("/mock/profiles");
        setProfiles(data);
      } catch {
        // fallback demo data
        setProfiles([
          { id: "1", name: "Sam", age: 28, bio: "Coffee + hikes" },
          { id: "2", name: "Liya", age: 26, bio: "Music + travel" },
        ]);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div style={{ padding: 16, maxWidth: 720, margin: "0 auto" }}>
      <h1>Search</h1>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div style={{ display: "grid", gap: 12 }}>
          {profiles.map((p) => (
            <ProfileCard key={p.id} profile={p} />
          ))}
        </div>
      )}
    </div>
  );
}
