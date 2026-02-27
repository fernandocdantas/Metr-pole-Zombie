import { Head, router } from '@inertiajs/react';
import { Plus, RefreshCw, Shield, ShieldOff } from 'lucide-react';
import { useState } from 'react';
import { fetchAction } from '@/lib/fetch-action';
import AppLayout from '@/layouts/app-layout';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { BreadcrumbItem } from '@/types';

type PlayerEntry = {
    username: string;
    name: string;
    character_name: string | null;
    whitelisted: boolean;
    role: string;
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: '/dashboard' },
    { title: 'Whitelist', href: '/admin/whitelist' },
];

const roleBadgeVariant: Record<string, 'default' | 'secondary' | 'outline'> = {
    super_admin: 'default',
    admin: 'default',
    moderator: 'secondary',
    player: 'outline',
};

export default function Whitelist({ players }: { players: PlayerEntry[] }) {
    const [showAdd, setShowAdd] = useState(false);
    const [passwordTarget, setPasswordTarget] = useState<string | null>(null);
    const [removeTarget, setRemoveTarget] = useState<string | null>(null);
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [syncing, setSyncing] = useState(false);

    const whitelistedCount = players.filter((p) => p.whitelisted).length;

    async function addUser() {
        setLoading(true);
        await fetchAction('/admin/whitelist', {
            data: { username, password },
            successMessage: `Added ${username} to whitelist`,
        });
        setLoading(false);
        setShowAdd(false);
        setUsername('');
        setPassword('');
        router.reload({ only: ['players'] });
    }

    function toggleWhitelist(target: string, isWhitelisted: boolean) {
        if (isWhitelisted) {
            setRemoveTarget(target);
        } else {
            setPasswordTarget(target);
        }
    }

    async function confirmAddToWhitelist() {
        if (!passwordTarget || !password) return;
        setLoading(true);
        await fetchAction(`/admin/whitelist/${passwordTarget}/toggle`, {
            data: { password },
            successMessage: `Whitelisted ${passwordTarget}`,
        });
        setLoading(false);
        setPasswordTarget(null);
        setPassword('');
        router.reload({ only: ['players'] });
    }

    async function confirmRemoveFromWhitelist() {
        if (!removeTarget) return;
        setLoading(true);
        await fetchAction(`/admin/whitelist/${removeTarget}/toggle`, {
            data: {},
            successMessage: `Removed ${removeTarget} from whitelist`,
        });
        setLoading(false);
        setRemoveTarget(null);
        router.reload({ only: ['players'] });
    }

    async function syncWhitelist() {
        setSyncing(true);
        await fetchAction('/admin/whitelist/sync', {
            successMessage: 'Whitelist synced',
        });
        setSyncing(false);
        router.reload({ only: ['players'] });
    }

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Whitelist" />
            <div className="flex flex-1 flex-col gap-6 p-4 lg:p-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight">Whitelist Management</h1>
                        <p className="text-muted-foreground">
                            {whitelistedCount} of {players.length} player{players.length !== 1 ? 's' : ''} whitelisted
                        </p>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" onClick={syncWhitelist} disabled={syncing}>
                            <RefreshCw className={`mr-1.5 size-4 ${syncing ? 'animate-spin' : ''}`} />
                            Sync
                        </Button>
                        <Button onClick={() => setShowAdd(true)}>
                            <Plus className="mr-1.5 size-4" />
                            Add User
                        </Button>
                    </div>
                </div>

                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Shield className="size-5" />
                            All Players
                        </CardTitle>
                        <CardDescription>
                            All known players. Toggle whitelist to control who can join when the server requires whitelist (Open=false).
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        {players.length > 0 ? (
                            <div className="space-y-2">
                                {players.map((player) => (
                                    <div
                                        key={player.username}
                                        className="flex items-center justify-between rounded-lg border border-border/50 px-4 py-3"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div>
                                                <div className="flex items-center gap-2">
                                                    <span className="font-medium">{player.username}</span>
                                                    <Badge variant={roleBadgeVariant[player.role] ?? 'outline'}>
                                                        {player.role}
                                                    </Badge>
                                                    {player.whitelisted && (
                                                        <Badge variant="default" className="bg-green-600 hover:bg-green-700">
                                                            Whitelisted
                                                        </Badge>
                                                    )}
                                                </div>
                                                {player.character_name && player.character_name !== player.username && (
                                                    <p className="text-sm text-muted-foreground">
                                                        Character: {player.character_name}
                                                    </p>
                                                )}
                                            </div>
                                        </div>
                                        <Button
                                            variant={player.whitelisted ? 'outline' : 'default'}
                                            size="sm"
                                            onClick={() => toggleWhitelist(player.username, player.whitelisted)}
                                        >
                                            {player.whitelisted ? (
                                                <>
                                                    <ShieldOff className="mr-1.5 size-4" />
                                                    Remove
                                                </>
                                            ) : (
                                                <>
                                                    <Shield className="mr-1.5 size-4" />
                                                    Whitelist
                                                </>
                                            )}
                                        </Button>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <p className="py-8 text-center text-muted-foreground">No players found. Run account sync to discover players.</p>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Add New User Dialog */}
            <Dialog open={showAdd} onOpenChange={setShowAdd}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Add User to Whitelist</DialogTitle>
                        <DialogDescription>
                            Create PZ credentials for a new user. They will use these to join the server.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="wl-username">Username</Label>
                            <Input
                                id="wl-username"
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                placeholder="PZ username"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="wl-password">Password</Label>
                            <Input
                                id="wl-password"
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="PZ password"
                            />
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowAdd(false)}>Cancel</Button>
                        <Button disabled={loading || !username || !password} onClick={addUser}>
                            Add User
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Password Dialog for Whitelisting */}
            <Dialog open={passwordTarget !== null} onOpenChange={() => { setPasswordTarget(null); setPassword(''); }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Set PZ Password</DialogTitle>
                        <DialogDescription>
                            Set a password for <strong>{passwordTarget}</strong> to add them to the PZ whitelist.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-2">
                        <Label htmlFor="toggle-password">Password</Label>
                        <Input
                            id="toggle-password"
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="PZ password"
                        />
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => { setPasswordTarget(null); setPassword(''); }}>Cancel</Button>
                        <Button disabled={loading || !password} onClick={confirmAddToWhitelist}>
                            Add to Whitelist
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Confirm Remove Dialog */}
            <Dialog open={removeTarget !== null} onOpenChange={() => setRemoveTarget(null)}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Remove from Whitelist</DialogTitle>
                        <DialogDescription>
                            Remove <strong>{removeTarget}</strong> from the whitelist?
                            They will no longer be able to join if the server requires whitelist.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setRemoveTarget(null)}>Cancel</Button>
                        <Button
                            variant="destructive"
                            disabled={loading}
                            onClick={confirmRemoveFromWhitelist}
                        >
                            Remove
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </AppLayout>
    );
}
