import "./globals.css";
import BottomNav from "../components/BottomNav";

export const metadata = {
  title: "FetaDating",
  description: "Dating app frontend",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, Arial" }}>
        <main style={{ paddingBottom: 72 }}>{children}</main>
        <BottomNav />
      </body>
    </html>
  );
}
