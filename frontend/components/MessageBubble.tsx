export default function MessageBubble({
  fromMe,
  text,
}: {
  fromMe: boolean;
  text: string;
}) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: fromMe ? "flex-end" : "flex-start",
      }}
    >
      <div
        style={{
          maxWidth: "75%",
          padding: "10px 12px",
          borderRadius: 14,
          border: "1px solid #ddd",
        }}
      >
        {text}
      </div>
    </div>
  );
}
