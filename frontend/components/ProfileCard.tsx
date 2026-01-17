import Link from "next/link";

export default function ProfileCard({
  profile,
}: {
  profile: { id: string; name: string; age?: number; bio?: string };
}) {
  return (
    <Link
      href={`/profile/${profile.id}`}
      style={{
        display: "block",
        textDecoration: "none",
        border: "1px solid #ddd",
        borderRadius: 12,
        padding: 16,
        color: "inherit",
      }}
    >
      <div style={{ fontSize: 18, fontWeight: 700 }}>
        {profile.name} {profile.age ? `· ${profile.age}` : ""}
      </div>
      {profile.bio && <div style={{ marginTop: 6 }}>{profile.bio}</div>}
    </Link>
  );
}
