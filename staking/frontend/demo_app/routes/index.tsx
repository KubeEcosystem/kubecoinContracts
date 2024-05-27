import { useSignal } from "@preact/signals";
import SPA from "../islands/SPA.tsx";

export default function Home() {
  const count = useSignal(3);
  return (
    <div>
      <SPA />
    </div>
  );
}
