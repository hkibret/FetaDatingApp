import { apiPost } from "./api";

export async function login(email: string, password: string) {
  // replace endpoint later
  try {
    const data = await apiPost<{ token: string }>("/auth/login", {
      email,
      password,
    });
    localStorage.setItem("token", data.token);
    return data;
  } catch {
    // demo fallback
    localStorage.setItem("token", "demo-token");
    return { token: "demo-token" };
  }
}

export async function register(name: string, email: string, password: string) {
  try {
    const data = await apiPost<{ token: string }>("/auth/register", {
      name,
      email,
      password,
    });
    localStorage.setItem("token", data.token);
    return data;
  } catch {
    localStorage.setItem("token", "demo-token");
    return { token: "demo-token" };
  }
}

export function logout() {
  localStorage.removeItem("token");
}
