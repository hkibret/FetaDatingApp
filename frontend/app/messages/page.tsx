"use client";

import { useState } from "react";
import MessageBubble from "../../components/MessageBubble";

type Msg = { id: string; fromMe: boolean; text: string };

export default function MessagesPage() {
  const [messages, setMessages] = useState<Msg[]>([
    { id: "1", fromMe: false, text: "Hi 👋" },
    { id: "2", fromMe: true, text: "Hey! How’s your day?" },
  ]);
  const [text, setText] = useState("");

  function send() {
    if (!text.trim()) return;
    setMessages((m) => [...m, { id: String(Date.now()), fromMe: true, text }]);
    setText("");
  }

  return (
    <div style={{ padding: 16, maxWidth: 720, margin: "0 auto" }}>
      <h1>Messages</h1>

      <div style={{ display: "grid", gap: 8, marginTop: 12 }}>
        {messages.map((m) => (
          <MessageBubble key={m.id} fromMe={m.fromMe} text={m.text} />
        ))}
      </div>

      <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Type a message"
          style={{ flex: 1, padding: 12 }}
        />
        <button onClick={send} style={{ padding: "12px 16px" }}>
          Send
        </button>
      </div>
    </div>
  );
}
