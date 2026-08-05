# Pulse Frontend - Invite accept/decline flow (BOM-safe)
# Run from inside your pulse-frontend folder:
#   powershell -ExecutionPolicy Bypass -File setup-invite-flow-frontend.ps1

Write-Host "Adding invite accept/decline UI..." -ForegroundColor Cyan

$enc = New-Object System.Text.UTF8Encoding $false

$c0 = @'
'use client';

import { useEffect, useState } from 'react';
import { useMe } from '@/lib/hooks/useAuth';

const STORAGE_KEY = 'pulse_active_workspace_id';
const EVENT_NAME = 'pulse:workspace-changed';

function readStored(): number | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw ? Number(raw) : null;
}

/**
 * Returns the workspace id that every workspace-scoped hook (useTasks,
 * useNotes, useCalendarEvents, useMembers, ...) should filter by.
 *
 * Only considers memberships with status !== 'invited' -- a pending
 * invitation the person hasn't accepted yet isn't a usable workspace
 * context (the backend would reject any request scoped to it).
 *
 * Priority: whatever the person last explicitly switched to (persisted
 * in localStorage), falling back to their first accepted membership.
 */
export function useWorkspaceId(): number | undefined {
  const { data: user } = useMe();
  const [stored, setStored] = useState<number | null>(() => readStored());

  useEffect(() => {
    const handler = () => setStored(readStored());
    window.addEventListener(EVENT_NAME, handler);
    return () => window.removeEventListener(EVENT_NAME, handler);
  }, []);

  const activeMemberships = (user?.workspace_memberships ?? []).filter(
    (m) => m.status !== 'invited'
  );
  const validStoredId = activeMemberships.find((m) => m.workspace_id === stored)?.workspace_id;

  return validStoredId ?? activeMemberships[0]?.workspace_id;
}

/**
 * Switches the active workspace. Every workspace-scoped React Query hook
 * keys its cache by workspaceId, so this alone is enough to make the
 * whole app (Tasks, Notes, Calendar, Team) refetch for the new
 * workspace -- no manual invalidation or page reload needed.
 */
export function setActiveWorkspaceId(id: number) {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_KEY, String(id));
  window.dispatchEvent(new Event(EVENT_NAME));
}
'@
[System.IO.File]::WriteAllText("lib\hooks\useWorkspace.ts", $c0, $enc)
Write-Host "  Updated: lib\hooks\useWorkspace.ts"

$c1 = @'
'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { api, ApiError } from '@/lib/api/client';

export function useAcceptInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    // No workspaceId header needed -- this endpoint verifies ownership
    // of the invitation directly, independent of the active workspace.
    mutationFn: (memberId: number) => api.post(`/workspace/members/${memberId}/accept`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['me'] });
      toast.success('Invitation accepted');
    },
    onError: (err) => {
      const message = err instanceof ApiError ? err.message : 'Could not accept invitation.';
      toast.error(message);
    },
  });
}

export function useDeclineInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (memberId: number) => api.post(`/workspace/members/${memberId}/decline`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['me'] });
      toast.success('Invitation declined');
    },
    onError: (err) => {
      const message = err instanceof ApiError ? err.message : 'Could not decline invitation.';
      toast.error(message);
    },
  });
}
'@
[System.IO.File]::WriteAllText("lib\hooks\useInvites.ts", $c1, $enc)
Write-Host "  Updated: lib\hooks\useInvites.ts"

$c2 = @'
'use client';

import { useState } from 'react';
import { ChevronsUpDown, Check, Mail } from 'lucide-react';
import { useMe } from '@/lib/hooks/useAuth';
import { useWorkspaceId, setActiveWorkspaceId } from '@/lib/hooks/useWorkspace';
import { useAcceptInvite, useDeclineInvite } from '@/lib/hooks/useInvites';
import { cn } from '@/lib/utils';

export function WorkspaceSwitcher() {
  const [open, setOpen] = useState(false);
  const { data: user } = useMe();
  const activeId = useWorkspaceId();
  const acceptInvite = useAcceptInvite();
  const declineInvite = useDeclineInvite();

  const memberships = user?.workspace_memberships ?? [];
  const activeMemberships = memberships.filter((m) => m.status !== 'invited');
  const pendingInvites = memberships.filter((m) => m.status === 'invited');
  const active = activeMemberships.find((m) => m.workspace_id === activeId);

  if (memberships.length === 0) {
    return <span className="text-sm font-medium text-text-primary">Workspace</span>;
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-1.5 rounded-sm px-2 py-1.5 text-sm font-medium text-text-primary hover:bg-bg-surface"
      >
        <span className="max-w-[160px] truncate">{active?.workspace.name ?? 'Workspace'}</span>
        {pendingInvites.length > 0 && (
          <span className="flex h-4 w-4 items-center justify-center rounded-full bg-danger text-[10px] font-semibold text-white">
            {pendingInvites.length}
          </span>
        )}
        {activeMemberships.length > 1 && (
          <ChevronsUpDown size={13} strokeWidth={1.5} className="shrink-0 text-text-tertiary" />
        )}
      </button>

      {open && (
        <>
          <button
            type="button"
            aria-hidden
            tabIndex={-1}
            onClick={() => setOpen(false)}
            className="fixed inset-0 z-40 cursor-default"
          />
          <div className="absolute left-0 top-full z-50 mt-1 w-72 rounded-md border border-border bg-bg-elevated py-1 shadow-md">
            {pendingInvites.length > 0 && (
              <>
                <div className="px-3 py-1.5 text-xs font-medium uppercase tracking-wide text-text-tertiary">
                  Pending invitations
                </div>
                {pendingInvites.map((m) => (
                  <div key={m.workspace_id} className="px-3 py-2">
                    <div className="flex items-center gap-1.5 text-sm font-medium text-text-primary">
                      <Mail size={13} strokeWidth={1.5} className="shrink-0 text-warning" />
                      <span className="truncate">{m.workspace.name}</span>
                    </div>
                    <p className="mt-0.5 text-xs text-text-tertiary">
                      Invited as {m.role}
                    </p>
                    <div className="mt-1.5 flex gap-2">
                      <button
                        type="button"
                        onClick={() => acceptInvite.mutate(m.id)}
                        disabled={acceptInvite.isPending}
                        className="rounded-sm bg-brand-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-brand-500 disabled:opacity-50"
                      >
                        Accept
                      </button>
                      <button
                        type="button"
                        onClick={() => declineInvite.mutate(m.id)}
                        disabled={declineInvite.isPending}
                        className="rounded-sm border border-border px-2.5 py-1 text-xs font-medium text-text-secondary hover:bg-bg-surface disabled:opacity-50"
                      >
                        Decline
                      </button>
                    </div>
                  </div>
                ))}
                <div className="my-1 border-t border-border" />
              </>
            )}

            <div className="px-3 py-1.5 text-xs font-medium uppercase tracking-wide text-text-tertiary">
              Your workspaces
            </div>
            {activeMemberships.map((m) => (
              <button
                key={m.workspace_id}
                type="button"
                onClick={() => {
                  setActiveWorkspaceId(m.workspace_id);
                  setOpen(false);
                }}
                className={cn(
                  'flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-bg-surface',
                  m.workspace_id === activeId && 'bg-brand-100 dark:bg-brand-600/10'
                )}
              >
                <div className="min-w-0">
                  <div className="truncate font-medium text-text-primary">{m.workspace.name}</div>
                  <div className="text-xs capitalize text-text-tertiary">{m.role}</div>
                </div>
                {m.workspace_id === activeId && (
                  <Check size={14} strokeWidth={2} className="shrink-0 text-brand-600" />
                )}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
'@
[System.IO.File]::WriteAllText("components\layout\WorkspaceSwitcher.tsx", $c2, $enc)
Write-Host "  Updated: components\layout\WorkspaceSwitcher.tsx"

Write-Host "Done. No new packages needed. Refresh your browser." -ForegroundColor Green
