# MVP Plan Annotation

Source image: `assets/plans/apartment_plan_mvp.jpeg`

Image size: `1000x1000`

Coordinates are normalized to `0...1` and refer to contour points on the plan image.

## Initial Zone Set

| id | title | type | contour mode |
| --- | --- | --- | --- |
| bathroom_01 | Санузел | ceiling | polygon |
| hallway_01 | Прихожая | floor | polygon |
| bedroom_01 | Спальня | floor | polygon |
| kitchen_01 | Кухня | floor | polygon |
| living_room_01 | Гостиная | floor | polygon |
| bedroom_window_01 | Окно спальни | window | thin polygon |
| living_window_01 | Окно гостиной | window | thin polygon |
| kitchen_wall_01 | Стена кухни слева | wall | thin polygon |
| living_wall_01 | Стена гостиной сверху | wall | thin polygon |

## Notes

- These are MVP contours, not legal BIM/CAD contours.
- Each contour is slightly forgiving to make iPhone taps easier without falling back to full rectangular overlays.
- Next refinement step: split long walls and openings into smaller selectable segments where defect localization matters.
