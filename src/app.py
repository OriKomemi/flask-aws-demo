from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)

# Use SQLite for testing, PostgreSQL otherwise
if os.getenv("TESTING"):
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
else:
    db_user = os.getenv("DB_USER", "user")
    db_pass = os.getenv("DB_PASSWORD", "pass")
    db_host = os.getenv("DB_HOST", "db")
    db_name = os.getenv("DB_NAME", "appdb")
    app.config["SQLALCHEMY_DATABASE_URI"] = f"postgresql://{db_user}:{db_pass}@{db_host}/{db_name}"

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)

    def to_dict(self):
        return {"id": self.id, "name": self.name}

@app.route("/")
def index():
    return "Hello from Flask + SQLAlchemy + Postgres!"

@app.route("/users", methods=["GET", "POST"])
def users():
    if request.method == "POST":
        data = request.get_json()
        new_user = User(name=data["name"])  # type: ignore
        db.session.add(new_user)
        db.session.commit()
        return jsonify(new_user.to_dict()), 201

    all_users = User.query.all()
    return jsonify([u.to_dict() for u in all_users])

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0", port=8000)
