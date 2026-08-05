<?php

// @formatter:off
// phpcs:ignoreFile
/**
 * A helper file for your Eloquent Models
 * Copy the phpDocs from this file to the correct Model,
 * And remove them from this file, to prevent double declarations.
 *
 * @author Barry vd. Heuvel <barryvdh@gmail.com>
 */


namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property int $user_id
 * @property string $feature
 * @property int $tokens_used
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereFeature($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereTokensUsed($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereUserId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|AiUsageLog whereWorkspaceId($value)
 */
	class AiUsageLog extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property int $created_by
 * @property int|null $linked_task_id
 * @property string $title
 * @property string|null $description
 * @property \Illuminate\Support\Carbon $start_at
 * @property \Illuminate\Support\Carbon $end_at
 * @property bool $is_meeting
 * @property string|null $meeting_url
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\User> $attendees
 * @property-read int|null $attendees_count
 * @property-read \App\Models\User $creator
 * @property-read \App\Models\Task|null $linkedTask
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereCreatedBy($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereDescription($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereEndAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereIsMeeting($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereLinkedTaskId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereMeetingUrl($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereStartAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereTitle($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|CalendarEvent whereWorkspaceId($value)
 */
	class CalendarEvent extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property string $name
 * @property string $color
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Task> $tasks
 * @property-read int|null $tasks_count
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereColor($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Category whereWorkspaceId($value)
 */
	class Category extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property string $name
 * @property string $color
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Task> $tasks
 * @property-read int|null $tasks_count
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereColor($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Label whereWorkspaceId($value)
 */
	class Label extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property int $created_by
 * @property string $title
 * @property string|null $content_markdown
 * @property bool $is_pinned
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $creator
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereContentMarkdown($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereCreatedBy($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereIsPinned($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereTitle($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Note whereWorkspaceId($value)
 */
	class Note extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property int|null $category_id
 * @property int $created_by
 * @property int|null $assigned_to
 * @property string $title
 * @property string|null $description
 * @property string $status
 * @property string $priority
 * @property \Illuminate\Support\Carbon|null $due_date
 * @property bool $ai_generated
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User|null $assignee
 * @property-read \App\Models\Category|null $category
 * @property-read \App\Models\User $creator
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Label> $labels
 * @property-read int|null $labels_count
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereAiGenerated($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereAssignedTo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereCategoryId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereCreatedBy($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereDescription($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereDueDate($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task wherePriority($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereStatus($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereTitle($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Task whereWorkspaceId($value)
 */
	class Task extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $password
 * @property string|null $avatar_url
 * @property \Illuminate\Support\Carbon|null $email_verified_at
 * @property string|null $remember_token
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Notifications\DatabaseNotificationCollection<int, \Illuminate\Notifications\DatabaseNotification> $notifications
 * @property-read int|null $notifications_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Workspace> $ownedWorkspaces
 * @property-read int|null $owned_workspaces_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\WorkspaceMember> $workspaceMemberships
 * @property-read int|null $workspace_memberships_count
 * @method static \Database\Factories\UserFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereAvatarUrl($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereEmailVerifiedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User wherePassword($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereRememberToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereUpdatedAt($value)
 */
	class User extends \Eloquent implements \Tymon\JWTAuth\Contracts\JWTSubject {}
}

namespace App\Models{
/**
 * @property int $id
 * @property string $name
 * @property string $slug
 * @property int $owner_id
 * @property string $plan
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\WorkspaceMember> $members
 * @property-read int|null $members_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Note> $notes
 * @property-read int|null $notes_count
 * @property-read \App\Models\User $owner
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Task> $tasks
 * @property-read int|null $tasks_count
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereOwnerId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace wherePlan($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereSlug($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Workspace whereUpdatedAt($value)
 */
	class Workspace extends \Eloquent {}
}

namespace App\Models{
/**
 * @property int $id
 * @property int $workspace_id
 * @property int $user_id
 * @property string $role
 * @property string $status
 * @property \Illuminate\Support\Carbon|null $invited_at
 * @property \Illuminate\Support\Carbon|null $joined_at
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @property-read \App\Models\Workspace $workspace
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereInvitedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereJoinedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereRole($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereStatus($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereUserId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|WorkspaceMember whereWorkspaceId($value)
 */
	class WorkspaceMember extends \Eloquent {}
}

