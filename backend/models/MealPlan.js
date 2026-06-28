import db from "../config/db.js";

class MealPlan {

    // add recipe to meal plan

    static async create(userId, mealData) {
        const { recipe_id, planned_date, meal_date, meal_type } = mealData;
        const date=planned_date || meal_date;

        const result=await db.query(
            `INSERT INTO meal_plans(user_id,recipe_id,meal_date,meal_type)`
        )

    }
}