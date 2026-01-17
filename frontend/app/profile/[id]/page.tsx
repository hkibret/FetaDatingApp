type Props = { params: { id: string } };

export default function ProfilePage({ params }: Props) {
  return (
    <div style={{ padding: 16, maxWidth: 720, margin: "0 auto" }}>
      <h1>Profile {params.id}</h1>
      <p>Load profile details here.</p>
    </div>
  );
}
