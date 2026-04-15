# Swipe Reviews Rollout

## Feature Flags

- `feature_swipe_reviews_enabled`: enable resident swipe deck and review form.
- `feature_review_moderation_enabled`: enable admin moderation queue/actions.
- `feature_rewards_enabled`: enable 1000-approved-review gift card issuance.

## Safety Controls

- Server-side rate limiting in `submit_swipe_review` (hourly cap per user).
- Mandatory moderation before public visibility/reputation updates.
- Admin-only moderation RPC with reason capture.
- Optional media accepted with strict extension filtering in client.

## Core Metrics

- `swipe_to_review_conversion`: count(submitted_reviews) / count(swipes).
- `moderation_approval_rate`: approved / total moderated.
- `moderation_backlog`: pending review count.
- `review_publish_latency_minutes`: moderation timestamp - submission timestamp.
- `reward_issuance_count`: milestones issued by day/week.

## Alerting Baselines

- Backlog alert when pending reviews > 250.
- Upload failure alert when media upload errors > 5% within 15 minutes.
- Reward anomaly alert when reward issuance spikes > 3x weekly baseline.

## Staged Rollout

1. Internal admins only, verify queue and moderation actions.
2. 10% resident cohort, monitor submission quality and abuse signals.
3. 50% rollout after stable moderation SLA and low upload failures.
4. 100% rollout with rewards fully enabled.
