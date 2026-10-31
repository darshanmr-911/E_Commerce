from django.core.management.base import BaseCommand

from apps.catalog.models import Category


CATEGORIES = (
    ("Vegetables", "Fresh vegetables for everyday meals."),
    ("Fruits", "Fresh seasonal fruit."),
    ("Dairy", "Milk, dairy and chilled staples."),
    ("Rice & Pulses", "Rice, grains and pulses."),
    ("Snacks", "Snacks and quick bites."),
    ("Beverages", "Drinks for every day."),
    ("Oil & Spices", "Cooking oils and spices."),
    ("Bakery", "Bread and bakery staples."),
    ("Personal Care", "Everyday personal care essentials."),
    ("Household", "Useful essentials for your home."),
    ("Dry Fruits", "Nuts and dried fruit."),
    ("Frozen Foods", "Frozen groceries and favourites."),
)


class Command(BaseCommand):
    help = "Create or update FreshKart's standard grocery categories."

    def handle(self, *args, **options):
        created = 0
        for name, description in CATEGORIES:
            _, was_created = Category.objects.update_or_create(
                name=name,
                defaults={"description": description, "is_active": True},
            )
            created += int(was_created)
        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {len(CATEGORIES)} categories ({created} newly created)."
            )
        )
