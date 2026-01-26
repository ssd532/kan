import { useCallback, useRef } from "react";
import type { RefObject } from "react";

interface UseAutoScrollOnDragOptions {
  scrollContainerRef: RefObject<HTMLElement>;
  edgeThreshold?: number;
  maxScrollSpeed?: number;
}

export function useAutoScrollOnDrag({
  scrollContainerRef,
  edgeThreshold = 100,
  maxScrollSpeed = 25,
}: UseAutoScrollOnDragOptions) {
  const isDragging = useRef(false);
  const animationFrameId = useRef<number | null>(null);
  const pointerPosition = useRef({ x: 0, y: 0 });

  const handlePointerMove = useCallback((e: PointerEvent) => {
    pointerPosition.current = { x: e.clientX, y: e.clientY };
  }, []);

  const scrollLoop = useCallback(() => {
    if (!isDragging.current || !scrollContainerRef.current) return;

    const container = scrollContainerRef.current;
    const rect = container.getBoundingClientRect();
    const { x } = pointerPosition.current;

    const distanceFromLeft = x - rect.left;
    const distanceFromRight = rect.right - x;

    let didScroll = false;

    if (distanceFromLeft < edgeThreshold && distanceFromLeft > 0) {
      const intensity = 1 - distanceFromLeft / edgeThreshold;
      container.scrollLeft -= maxScrollSpeed * intensity;
      didScroll = true;
    }

    if (distanceFromRight < edgeThreshold && distanceFromRight > 0) {
      const intensity = 1 - distanceFromRight / edgeThreshold;
      container.scrollLeft += maxScrollSpeed * intensity;
      didScroll = true;
    }

    if (didScroll) {
      container.dispatchEvent(new Event("scroll", { bubbles: true }));

      const droppables = container.querySelectorAll("[data-rbd-droppable-id]");
      droppables.forEach((el) => {
        el.dispatchEvent(new Event("scroll", { bubbles: false }));
      });
    }

    animationFrameId.current = requestAnimationFrame(scrollLoop);
  }, [edgeThreshold, maxScrollSpeed, scrollContainerRef]);

  const handleDragStart = useCallback(() => {
    isDragging.current = true;
    document.addEventListener("pointermove", handlePointerMove, {
      passive: true,
    });
    animationFrameId.current = requestAnimationFrame(scrollLoop);
  }, [handlePointerMove, scrollLoop]);

  const handleDragEnd = useCallback(() => {
    isDragging.current = false;
    document.removeEventListener("pointermove", handlePointerMove);
    if (animationFrameId.current) {
      cancelAnimationFrame(animationFrameId.current);
      animationFrameId.current = null;
    }
  }, [handlePointerMove]);

  return { handleDragStart, handleDragEnd };
}
