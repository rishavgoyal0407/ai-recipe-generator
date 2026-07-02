/*

AI RECIPE GENERATOR DATABASE SCHEMA

DATABASE PURPOSE
----------------

This database powers an AI-based recipe generation platform.

Main Features Supported:

1. User Authentication
2. User Food Preferences
3. Pantry Management
4. AI Recipe Storage
5. Nutritional Information
6. Meal Planning
7. Shopping List Generation

DATABASE RELATIONSHIPS
----------------------

users
│
├── user_preferences
│
├── pantry_items
│
├── recipes
│   │
│   ├── recipe_ingredients
│   └── recipe_nutrition
│
├── meal_plans
│
└── shopping_list_items

DESIGN PRINCIPLES
-----------------

• UUIDs are used instead of integer IDs for security.
• Foreign keys maintain data integrity.
• ON DELETE CASCADE prevents orphan records.
• Indexes improve query performance.
• Triggers automatically maintain updated_at timestamps.
========================================================

*/

/*

UUID EXTENSION
--------------

WHY IS THIS NEEDED?

PostgreSQL cannot generate UUID values by default.

This extension provides:

uuid_generate_v4()

which automatically creates unique identifiers like:

550e8400-e29b-41d4-a716-446655440000

WHY USE UUIDS?

Instead of:

1
2
3
4

UUIDs are:

• Harder to guess
• Better for public APIs
• Common in production systems
• Safer for distributed applications
====================================

*/
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

/*
===============================================================================
TABLE: users
===============================================================================

PURPOSE
-------

Stores authentication and profile information for every user.

A user account is the root entity of the entire application.

Almost every table in the system eventually connects back
to a user record.

BUSINESS EXAMPLES
-----------------

User:
John Doe
john@gmail.com

This user may have:

• Pantry Items
• Saved Recipes
• Meal Plans
• Shopping Lists
• Food Preferences

RELATIONSHIPS
-------------

users
│
├── user_preferences
├── pantry_items
├── recipes
├── meal_plans
└── shopping_list_items

IMPORTANT RULES
---------------

1. Every user must have a unique email.
2. Passwords are stored as hashes, never plain text.
3. User records must be uniquely identifiable.
4. Creation and update timestamps are tracked.
===============================================================================
*/
CREATE TABLE IF NOT EXISTS users(

    /*
    Unique identifier for each user.

    WHY?

    Email addresses can change.

    IDs should never change.

    Therefore every user gets a permanent UUID.

    Example:

    550e8400-e29b-41d4-a716-446655440000
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Primary login identifier.

    WHY UNIQUE?

    Two users must never share the same email.

    Authentication depends on this.

    Password resets also depend on this.

    Example:

    john@gmail.com
    */
    email VARCHAR(55) UNIQUE NOT NULL,

    /*
    Stores encrypted password.

    NEVER store plain text passwords.

    Bad:
    password123

    Good:
    $2a$10$Q8x...

    Generated using bcrypt.
    */
    password_hash VARCHAR(255) NOT NULL,

    /*
    User's display name.

    Used throughout the application UI.

    Example:
    John Doe
    */
    name VARCHAR(255) NOT NULL,

    /*
    Records when account was created.

    Useful for:

    • Analytics
    • User history
    • Auditing
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Records latest modification time.

    Automatically updated using triggers.

    Useful for:

    • Auditing
    • Debugging
    • Tracking changes
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/*
===============================================================================
TABLE: user_preferences
===============================================================================

PURPOSE
-------

Stores food-related preferences for a user.

This table helps personalize the recipe generation experience.

Instead of recommending the same recipes to everyone,
the AI reads this table and adapts recommendations
according to the user's dietary needs and tastes.

WHY IS THIS A SEPARATE TABLE?

The users table is responsible for:

• Authentication
• Identity
• Account information

This table is responsible for:

• Food preferences
• Dietary restrictions
• Allergies
• Personalization settings

Keeping them separate follows database normalization
and makes the database easier to maintain.

REAL WORLD EXAMPLE
------------------

User:
John Doe

Preferences:
Vegetarian
Allergic to peanuts
Likes Italian cuisine
Usually cooks for 2 people

The AI should:

✓ Avoid meat recipes
✓ Avoid peanut ingredients
✓ Prefer Italian dishes
✓ Scale recipes for 2 servings

RELATIONSHIP
------------

users (1)
│
└── user_preferences (1)

One user can have only one preference profile.

BUSINESS RULES
--------------

1. Every preference profile belongs to a valid user.
2. A user can have only one preference profile.
3. Preferences directly influence AI recipe generation.
4. Allergies must always be respected when generating recipes.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS user_preferences(


    /*
    Unique identifier for this preference record.

    Even though this table belongs to a user,
    it still gets its own primary key.

    This makes future updates and relationships easier.
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Connects this preference profile to a user.

    REFERENCES users(id)
    ensures the user must exist before preferences
    can be created.

    ON DELETE CASCADE means:

    If a user account is deleted,
    automatically remove its preference profile.

    This prevents orphan records.
    */
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    /*
    Dietary restrictions followed by the user.

    Examples:

    ['vegetarian']
    ['vegan']
    ['keto']
    ['gluten-free']

    The AI checks this field before suggesting recipes.

    Example:

    User = vegetarian

    AI should NOT suggest:

    ✗ Chicken Curry
    ✗ Butter Chicken

    AI MAY suggest:

    ✓ Paneer Curry
    ✓ Veg Biryani
    */
    dietary_restrictions TEXT[] DEFAULT '{}',

    /*
    Food allergies that must be avoided.

    Examples:

    ['peanuts']
    ['milk']
    ['soy']

    This field is critical for food safety.

    Example:

    User allergy = peanuts

    AI must never suggest recipes
    containing peanuts.
    */
    allergies TEXT[] DEFAULT '{}',

    /*
    User's favorite cuisines.

    Examples:

    ['Indian']
    ['Italian']
    ['Mexican']

    Used to personalize recipe recommendations.

    Example:

    User likes Italian cuisine.

    AI may prioritize:

    ✓ Pasta
    ✓ Lasagna
    ✓ Risotto

    instead of random cuisines.
    */
    preferred_cuisines TEXT[] DEFAULT '{}',

    /*
    Default number of servings.

    Example:

    User usually cooks for:

    2 people
    4 people
    6 people

    AI can automatically scale ingredients
    according to this value.

    Default = 4 servings.
    */
    default_servings INT DEFAULT 4,

    /*
    Preferred measurement system.

    metric:
        grams
        kilograms
        liters

    imperial:
        ounces
        pounds
        cups

    This allows recipes to be displayed
    in a format familiar to the user.
    */
    measurement_unit VARCHAR(20) DEFAULT 'metric',

    /*
    Records when preference profile
    was first created.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Records the last modification time.

    Automatically maintained using triggers.
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Ensures one user can have only
    one preference profile.

    Without this constraint:

    User A
      → Profile 1
      → Profile 2
      → Profile 3

    which creates ambiguity.

    This guarantees:

    One User = One Preference Profile
    */
    UNIQUE(user_id)


);


/*
===============================================================================
TABLE: pantry_items
===============================================================================

PURPOSE
-------

Stores all ingredients currently available in a user's kitchen.

This table acts as a digital pantry.

Instead of asking users to manually remember what they own,
the application stores available ingredients and quantities.

The AI can use this information to generate recipes
based on ingredients already available at home.

BUSINESS USE CASE
-----------------

User's Pantry:

Rice        → 5 kg
Tomatoes    → 4 pieces
Milk        → 2 liters

AI can generate:

✓ Tomato Rice
✓ Fried Rice
✓ Rice Pudding

instead of suggesting recipes requiring ingredients
the user does not currently possess.

BUSINESS BENEFITS
-----------------

• Reduces food waste
• Saves grocery expenses
• Generates realistic recipes
• Enables smart shopping lists
• Tracks expiring ingredients

RELATIONSHIP
------------

users (1)
│
└── pantry_items (many)

One user can have many pantry items.

IMPORTANT RULES
---------------

1. Every pantry item belongs to a user.
2. Quantities must be stored separately from units.
3. Ingredients may have expiration dates.
4. Low-stock ingredients can be identified automatically.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS pantry_items(


    /*
    Unique identifier for a pantry item.

    Example:

    Rice Record
    Milk Record
    Egg Record

    Each receives its own UUID.
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Owner of this pantry item.

    WHY?

    Different users have different kitchens.

    Rice belonging to User A should never appear
    inside User B's pantry.

    ON DELETE CASCADE ensures pantry data is removed
    automatically when a user account is deleted.
    */
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    /*
    Ingredient name.

    Examples:

    Rice
    Milk
    Tomatoes
    Eggs
    Paneer

    This is usually the most frequently displayed field.
    */
    name VARCHAR(255) NOT NULL,

    /*
    Quantity currently available.

    Examples:

    5.00
    2.50
    0.75

    Stored separately from unit.

    This makes calculations easier.
    */
    quantity DECIMAL(10,2) NOT NULL,

    /*
    Measurement unit.

    Examples:

    kg
    grams
    liters
    pieces

    WHY SEPARATE FROM QUANTITY?

    Good Design:

    quantity = 5
    unit = kg

    Bad Design:

    "5kg"

    Separate fields allow filtering,
    calculations and conversions.
    */
    unit VARCHAR(50) NOT NULL,

    /*
    Groups ingredients into categories.

    Examples:

    Dairy
    Vegetables
    Fruits
    Grains
    Spices

    Useful for filtering pantry items
    and improving user experience.
    */
    category VARCHAR(100) NOT NULL,

    /*
    Expiration date of ingredient.

    Example:

    Milk expires on:
    2026-07-20

    Enables:

    • Expiry reminders
    • Waste reduction
    • Priority recipe generation
    */
    expiry_date DATE,

    /*
    Indicates whether inventory is running low.

    Example:

    Rice:
    Quantity = 0.20 kg

    System may automatically set:

    is_running_low = true

    Useful for shopping list generation.
    */
    is_running_low BOOLEAN DEFAULT FALSE,

    /*
    Stores when pantry item was added.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Stores last modification time.

    Updated automatically through triggers.
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP


);

/*
===============================================================================
TABLE: recipes
===============================================================================

PURPOSE
-------
Stores AI-generated recipes saved by users.

Each recipe contains metadata such as name, description,
cuisine type, difficulty level, preparation and cooking times,
serving count, structured instructions, dietary tags,
user notes, and an optional image.

BUSINESS USE CASE
-----------------

User requests:

"Generate a vegetarian Italian pasta recipe"

AI generates:

    Name:        Creamy Penne Alfredo
    Cuisine:     Italian
    Difficulty:  easy
    Prep Time:   10 minutes
    Cook Time:   20 minutes
    Servings:    4
    Instructions: [step1, step2, ...]

The recipe is stored in this table and can be:

• Viewed later
• Added to meal plans
• Used to generate shopping lists
• Rated and noted by the user

RELATIONSHIP
------------

users (1)
│
└── recipes (many)
    │
    ├── recipe_ingredients (many)
    └── recipe_nutrition (1)

One user can have many saved recipes.
Each recipe can have many ingredients and one nutrition record.

IMPORTANT RULES
---------------

1. Every recipe belongs to a user.
2. Difficulty must be one of: easy, medium, hard.
3. Instructions are stored as JSONB for flexible structure.
4. Dietary tags use a PostgreSQL array for multi-value support.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS recipes(

    /*
    Unique identifier for each recipe.

    Example:

    550e8400-e29b-41d4-a716-446655440000
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Owner of this recipe.

    Links recipe back to the user who generated/saved it.

    ON DELETE CASCADE ensures all recipes are removed
    automatically if the user account is deleted.
    */
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    /*
    Recipe name / title.

    Examples:

    Creamy Penne Alfredo
    Veg Biryani
    Chocolate Lava Cake
    */
    name VARCHAR(255) NOT NULL,

    /*
    Brief description of the recipe.

    Example:

    "A rich and creamy Italian pasta dish
     made with parmesan and butter."
    */
    description TEXT,

    /*
    Type of cuisine.

    Examples:

    Italian
    Indian
    Mexican
    Chinese
    */
    cuisine_type VARCHAR(100),

    /*
    Difficulty level of the recipe.

    Allowed values:

    easy
    medium
    hard

    CHECK constraint prevents invalid values.
    */
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy','medium','hard')),

    /*
    Time required for preparation (in minutes).

    Example:

    10 (minutes)
    */
    prep_time INT,

    /*
    Time required for cooking (in minutes).

    Example:

    20 (minutes)
    */
    cook_time INT,

    /*
    Number of servings the recipe yields.

    Default = 4 servings.
    */
    servings INT DEFAULT 4,

    /*
    Step-by-step cooking instructions.

    Stored as JSONB for flexible structure.

    Example:

    [
        {"step": 1, "text": "Boil pasta in salted water."},
        {"step": 2, "text": "Prepare the sauce."},
        {"step": 3, "text": "Combine and serve."}
    ]
    */
    instructions JSONB,

    /*
    Dietary tags associated with the recipe.

    Examples:

    {'vegetarian', 'gluten-free'}
    {'vegan', 'low-carb'}

    Stored as a PostgreSQL text array for multi-value support.
    */
    dietary_tags TEXT[] DEFAULT '{}',

    /*
    User's personal notes about the recipe.

    Example:

    "Added extra garlic last time, turned out great!"
    */
    user_notes TEXT,

    /*
    URL to the recipe image.

    Example:

    "https://example.com/images/pasta.jpg"
    */
    image_url TEXT,

    /*
    Records when recipe was first saved.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Records latest modification time.

    Automatically updated using triggers.
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
===============================================================================
TABLE: recipe_ingredients
===============================================================================

PURPOSE
-------
Stores ingredients required by a recipe.

WHY A SEPARATE TABLE?

A recipe can contain many ingredients.

Example:

Pasta Recipe

    Pasta
    Cheese
    Milk
    Butter

Storing ingredients in a separate table
follows database normalization principles.

RELATIONSHIP
------------

recipes (1)
    │
    └── recipe_ingredients (many)

One recipe can have many ingredients.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS recipe_ingredients(

    /*
    Unique ingredient record identifier.
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Links ingredient to recipe.

    If recipe is deleted,
    ingredients are automatically removed.
    */
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,

    /*
    Ingredient name.

    Examples:

    Rice
    Cheese
    Tomato
    Butter
    */
    ingredient_name VARCHAR(255) NOT NULL,

    /*
    Required quantity.

    Example:

    2.50
    */
    quantity DECIMAL(10,2) NOT NULL,

    /*
    Measurement unit.

    Examples:

    grams
    kg
    liters
    tbsp
    */
    unit VARCHAR(50) NOT NULL,

    /*
    Timestamp when ingredient record
    was created.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
===============================================================================
TABLE: recipe_nutrition
===============================================================================

PURPOSE
-------
Stores nutritional information for a recipe.

Each recipe can have one nutrition record containing
calorie count and macronutrient breakdown.

This data is typically generated by the AI alongside
the recipe itself.

BUSINESS USE CASE
-----------------

Recipe: Creamy Penne Alfredo

    Calories: 450.00
    Protein:  18.50 g
    Carbs:    52.00 g
    Fats:     20.00 g
    Fiber:     3.50 g

Users can use this information to:

• Track calorie intake
• Plan balanced meals
• Meet dietary goals

RELATIONSHIP
------------

recipes (1)
    │
    └── recipe_nutrition (1)

One recipe has exactly one nutrition record.

IMPORTANT RULES
---------------

1. Every nutrition record belongs to a recipe.
2. UNIQUE(recipe_id) ensures one-to-one relationship.
3. If recipe is deleted, nutrition data is removed too.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS recipe_nutrition(

    /*
    Unique identifier for the nutrition record.
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Links nutrition data to a recipe.

    ON DELETE CASCADE ensures nutrition data
    is automatically removed when the recipe is deleted.
    */
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,

    /*
    Total calories per serving.

    Example:

    450.00
    */
    calories DECIMAL(10,2),

    /*
    Protein content in grams.

    Example:

    18.50
    */
    protein DECIMAL(10,2),

    /*
    Carbohydrate content in grams.

    Example:

    52.00
    */
    carbs DECIMAL(10,2),

    /*
    Fat content in grams.

    Example:

    20.00
    */
    fats DECIMAL(10,2),

    /*
    Fiber content in grams.

    Example:

    3.50
    */
    fiber DECIMAL(10,2),

    /*
    Records when nutrition data was created.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Ensures one recipe has exactly one nutrition record.

    Without this constraint a recipe could accumulate
    multiple conflicting nutrition entries.
    */
    UNIQUE(recipe_id)
);

/*
===============================================================================
TABLE: meal_plans
===============================================================================

PURPOSE
-------
Stores a user's planned meals for specific dates.

This table powers meal planning functionality.

Users can schedule recipes for future meals.

BUSINESS USE CASE
-----------------

Monday:

Breakfast → Oatmeal
Lunch     → Paneer Wrap
Dinner    → Pasta

Tuesday:

Breakfast → Smoothie
Lunch     → Rice Bowl
Dinner    → Biryani

This allows users to organize meals
for days or weeks in advance.

RELATIONSHIPS
-------------

users (1)
    │
    └── meal_plans (many)

recipes (1)
    │
    └── meal_plans (many)

One user can create many meal plans.

One recipe can appear in many meal plans.

IMPORTANT RULES
---------------

1. Every meal plan belongs to a user.
2. Every meal plan references a recipe.
3. A user cannot have two breakfasts
   on the same day.
4. Meal type must be valid.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS meal_plans(

    /*
    Unique identifier for meal plan record.
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Owner of the meal plan.

    Example:

    John's weekly schedule.
    */
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    /*
    Recipe selected for this meal.

    Example:

    Monday Dinner
        → Veg Biryani
    */
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,

    /*
    Date when meal is scheduled.

    Example:

    2026-07-01
    */
    meal_date DATE NOT NULL,

    /*
    Defines meal category.

    Allowed values:

    breakfast
    lunch
    dinner

    CHECK constraint prevents invalid values.

    Examples NOT allowed:

    brunchhh
    snackss
    random
    */
    meal_type VARCHAR(20)
    NOT NULL
    CHECK (meal_type IN ('breakfast','lunch','dinner')),

    /*
    Records when meal plan was created.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Records last modification time.

    Automatically maintained by triggers.
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Prevents duplicate meal assignments.

    Example:

    User:
        John

    Date:
        2026-07-01

    Meal:
        Breakfast

    Only one breakfast can exist for that
    user on that date.

    This prevents schedule conflicts.
    */
    UNIQUE(user_id, meal_date, meal_type)
);



/*
===============================================================================
TABLE: shopping_list_items
===============================================================================

PURPOSE
-------
Stores ingredients that users need to purchase.

This table acts as a smart grocery shopping list.

Instead of manually writing shopping lists,
the application can automatically generate them
based on missing ingredients, meal plans,
and low-stock pantry items.

BUSINESS USE CASE
-----------------

User wants to cook:

    Pasta Alfredo

Required Ingredients:

    Pasta
    Cheese
    Milk
    Butter

Current Pantry:

    Pasta
    Milk

Missing Ingredients:

    Cheese
    Butter

The system can automatically create:

Shopping List:
    Cheese
    Butter

This improves user experience and helps
users purchase only what they actually need.

BUSINESS BENEFITS
-----------------

• Saves time
• Reduces forgotten ingredients
• Integrates with meal planning
• Uses pantry information intelligently
• Makes recipe preparation easier

RELATIONSHIP
------------

users (1)
    │
    └── shopping_list_items (many)

One user can have many shopping list items.

IMPORTANT RULES
---------------

1. Every shopping list item belongs to a user.
2. Quantities must be stored separately from units.
3. Items can be marked as purchased.
4. Shopping lists may be generated automatically.
===============================================================================
*/

CREATE TABLE IF NOT EXISTS shopping_list_items(

    /*
    Unique identifier for shopping list item.

    Every item receives its own UUID.

    Example:

    Cheese Item
    Milk Item
    Butter Item
    */
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    /*
    Identifies which user owns this shopping item.

    Example:

    User:
        John

    Shopping List:
        Cheese
        Butter
        Eggs

    ON DELETE CASCADE ensures all shopping
    items are removed automatically if the
    user account is deleted.
    */
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    /*
    Name of ingredient that needs to be purchased.

    Examples:

    Cheese
    Butter
    Milk
    Tomatoes
    Eggs

    This is usually the most visible field
    in the shopping list interface.
    */
    ingredient_name VARCHAR(255) NOT NULL,

    /*
    Quantity required.

    Examples:

    2.00
    5.50
    1.25

    Stored separately from unit for easier
    calculations and future conversions.
    */
    quantity DECIMAL(10,2) NOT NULL,

    /*
    Unit associated with quantity.

    Examples:

    kg
    grams
    liters
    pieces

    Good Design:

        quantity = 2
        unit = kg

    Bad Design:

        "2kg"

    Separate storage makes filtering,
    calculations and reporting easier.
    */
    unit VARCHAR(50) NOT NULL,

    /*
    Ingredient category.

    Examples:

    Dairy
    Vegetables
    Fruits
    Grains
    Spices

    Helps organize shopping lists and
    makes grocery shopping more efficient.
    */
    category VARCHAR(100),

    /*
    Indicates whether item has already
    been purchased.

    false = still needs to be purchased

    true = already purchased

    Default is FALSE because newly created
    shopping list items are usually pending.
    */
    is_checked BOOLEAN DEFAULT FALSE,

    /*
    Indicates whether this shopping list item
    was generated from a meal plan.

    false = manually added by the user

    true = auto-generated from a meal plan

    Default is FALSE because most items
    are added manually.
    */
    from_meal_plan BOOLEAN DEFAULT FALSE,

    /*
    Records when shopping item was created.

    Useful for tracking and analytics.
    */
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    /*
    Records the last modification time.

    Automatically maintained using triggers.
    */
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
===============================================================================
INDEXES
===============================================================================

PURPOSE
-------
Indexes are created to improve database query performance.

Without indexes, PostgreSQL may need to scan every row
in a table to find matching records.

This process is called a:

    Full Table Scan

As tables grow larger, full table scans become slower.

Indexes act like the index section of a book.

Instead of reading every page to find a topic,
the database can quickly jump to the correct location.

WHY ARE INDEXES IMPORTANT?
--------------------------

Example Query:

    SELECT *
    FROM pantry_items
    WHERE user_id = '123';

Without an index:

    PostgreSQL checks every row.

With an index:

    PostgreSQL directly finds matching rows.

This significantly improves performance.

TRADE-OFF
---------

Benefits:

✓ Faster SELECT queries
✓ Better filtering performance
✓ Better search performance
✓ Improved user experience

Costs:

• Slightly slower INSERT operations
• Slightly slower UPDATE operations
• Additional storage usage

Since this application performs many read operations,
indexes provide a significant performance advantage.

INDEX STRATEGY
--------------

Indexes are added on columns that are frequently used in:

• WHERE clauses
• Filtering operations
• Search operations
• User-specific queries
• Date-based queries

===============================================================================
*/

-- Index on pantry_items.user_id
-- Speeds up queries like: SELECT * FROM pantry_items WHERE user_id = ?
CREATE INDEX IF NOT EXISTS idx_pantry_items_user_id
ON pantry_items(user_id);

-- Index on recipes.user_id
-- Speeds up queries like: SELECT * FROM recipes WHERE user_id = ?
CREATE INDEX IF NOT EXISTS idx_recipes_user_id
ON recipes(user_id);

-- Index on recipe_ingredients.recipe_id
-- Speeds up queries like: SELECT * FROM recipe_ingredients WHERE recipe_id = ?
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id
ON recipe_ingredients(recipe_id);

-- Index on meal_plans.user_id
-- Speeds up queries like: SELECT * FROM meal_plans WHERE user_id = ?
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id
ON meal_plans(user_id);

-- Index on meal_plans.recipe_id
-- Speeds up joining meal plans with recipes
CREATE INDEX IF NOT EXISTS idx_meal_plans_recipe_id
ON meal_plans(recipe_id);

-- Index on meal_plans.meal_date
-- Speeds up date-based queries for meal planning
CREATE INDEX IF NOT EXISTS idx_meal_plans_meal_date
ON meal_plans(meal_date);

-- Index on shopping_list_items.user_id
-- Speeds up queries like: SELECT * FROM shopping_list_items WHERE user_id = ?
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_user_id
ON shopping_list_items(user_id);


/*
===============================================================================
FUNCTION: update_updated_at_column
===============================================================================

PURPOSE
-------
Automatically updates the 'updated_at' column whenever
a record is modified.

WHY DO WE NEED THIS?
--------------------

Most tables in this database contain two timestamps:

    created_at
    updated_at

Example:

User created account:

    created_at = 2026-06-25 10:00:00
    updated_at = 2026-06-25 10:00:00

Later user changes name:

    created_at = 2026-06-25 10:00:00
    updated_at = 2026-06-30 14:25:00

Notice that:

• created_at never changes
• updated_at should always reflect the latest modification

Without this function, developers would need to manually write:

    UPDATE users
    SET name = 'John',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = ?;

every single time a record is updated.

This is repetitive and easy to forget.

To solve this problem, PostgreSQL allows us to create
a reusable function that automatically updates
the updated_at column before every UPDATE operation.

HOW IT WORKS
------------

Step 1:
A row is updated.

Step 2:
A trigger runs automatically.

Step 3:
update_updated_at_column() Runs

Step 4:
updated_at is replaced with the current timestamp.

Step 5:
The updated row is saved.

RESULT
------

Every table always has an accurate updated_at value
without requiring manual updates in application code.

BENEFITS
--------

✓ Less repetitive code
✓ Prevents developer mistakes
✓ Keeps timestamps accurate
✓ Works automatically across multiple tables

===============================================================================
*/

CREATE OR REPLACE FUNCTION update_updated_at_column()

/*
RETURNS TRIGGER

This tells PostgreSQL that this function
will be executed by a trigger.

A trigger is an automatic action that runs
when a database event occurs.

Examples:

    INSERT
    UPDATE
    DELETE
*/
RETURNS TRIGGER AS $$

BEGIN

    /*
    NEW represents the row being updated.

    Example:

    Before update:

        updated_at = 2026-06-25

    After update:

        updated_at = CURRENT_TIMESTAMP

    CURRENT_TIMESTAMP returns the current
    date and time from PostgreSQL.
    */
    NEW.updated_at = CURRENT_TIMESTAMP;

    /*
    PostgreSQL requires trigger functions
    to return the row that should be saved.

    Here we return the modified row
    containing the new updated_at value.
    */
    RETURN NEW;

END;

/*
$$ marks the end of the function body.

LANGUAGE plpgsql tells PostgreSQL that
this function is written using PL/pgSQL,
PostgreSQL's procedural language.
*/
$$ LANGUAGE 'plpgsql';

/*
===============================================================================
TRIGGERS FOR AUTOMATIC updated_at MANAGEMENT
===============================================================================

PURPOSE
-------
These triggers automatically update the 'updated_at'
column whenever a record is modified.

The triggers use the function:

    update_updated_at_column()

created earlier in this schema.

WHY DO WE NEED TRIGGERS?
------------------------

Without triggers, developers must manually update
the updated_at column every time a row changes.

Example:

    UPDATE users
    SET name = 'John',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = ?;

This approach has problems:

• Developers can forget to update updated_at
• Code becomes repetitive
• Timestamps may become inaccurate

Triggers solve this problem automatically.

HOW TRIGGERS WORK
-----------------

When an UPDATE query is executed:

    UPDATE users
    SET name = 'John'
    WHERE id = ?;

PostgreSQL performs the following steps:

    Row Update Requested
            ↓
    Trigger Executes
            ↓
    update_updated_at_column() Runs
            ↓
    updated_at Gets New Timestamp
            ↓
    Row Saved

This process happens automatically.

WHAT DOES "BEFORE UPDATE" MEAN?
-------------------------------

BEFORE UPDATE means:

Execute the trigger before PostgreSQL
saves the modified row.

This allows the trigger function to modify
the row before it is written to the database.

WHAT DOES "FOR EACH ROW" MEAN?
------------------------------

If one row is updated:

    Trigger runs once.

If 100 rows are updated:

    Trigger runs 100 times.

Each row receives its own updated_at value.

BENEFITS
--------

✓ Automatic timestamp management
✓ Less application code
✓ Prevents human errors
✓ Consistent auditing information
✓ Easier maintenance

===============================================================================
*/

-- Trigger for users table
-- Automatically updates updated_at when a user record is modified
CREATE OR REPLACE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for user_preferences table
-- Automatically updates updated_at when preferences are modified
CREATE OR REPLACE TRIGGER update_user_preferences_updated_at
BEFORE UPDATE ON user_preferences
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for pantry_items table
-- Automatically updates updated_at when pantry items are modified
CREATE OR REPLACE TRIGGER update_pantry_items_updated_at
BEFORE UPDATE ON pantry_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for recipes table
-- Automatically updates updated_at when a recipe is modified
CREATE OR REPLACE TRIGGER update_recipes_updated_at
BEFORE UPDATE ON recipes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for meal_plans table
-- Automatically updates updated_at when a meal plan is modified
CREATE OR REPLACE TRIGGER update_meal_plans_updated_at
BEFORE UPDATE ON meal_plans
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for shopping_list_items table
-- Automatically updates updated_at when a shopping list item is modified
CREATE OR REPLACE TRIGGER update_shopping_list_items_updated_at
BEFORE UPDATE ON shopping_list_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();