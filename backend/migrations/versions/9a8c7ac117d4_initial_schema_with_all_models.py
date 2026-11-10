"""Initial schema with all models

Revision ID: 9a8c7ac117d4
Revises: 
Create Date: 2026-11-10 08:29:38.422903

"""

from alembic import op
import sqlalchemy as sa
import sqlalchemy_utils


# revision identifiers, used by Alembic.
revision = '9a8c7ac117d4'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Upgrade schema."""
    
    # Create enum types first
    proficiency_level = sa.Enum('beginner', 'intermediate', 'advanced', 'expert', name='proficiencylevel')
    proficiency_level.create(op.get_bind())
    
    career_proficiency = sa.Enum('beginner', 'intermediate', 'advanced', 'expert', name='careerproficiency')
    career_proficiency.create(op.get_bind())
    
    task_status = sa.Enum('completed', 'in_progress', 'not_started', name='taskstatus')
    task_status.create(op.get_bind())
    
    # Create tables
    
    # users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('username', sa.String(), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('is_superuser', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email'),
        sa.UniqueConstraint('username'),
    )
    
    # student_profiles table
    op.create_table(
        'student_profiles',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('institution', sa.String(), nullable=True),
        sa.Column('degree', sa.String(), nullable=True),
        sa.Column('academic_year', sa.String(), nullable=True),
        sa.Column('interests', sa.Text(), nullable=True),
        sa.Column('learning_goals', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    
    # student_skills table
    op.create_table(
        'student_skills',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('profile_id', sa.Integer(), nullable=True),
        sa.Column('skill_name', sa.String(), nullable=False),
        sa.Column('proficiency_level', sa.Enum('beginner', 'intermediate', 'advanced', 'expert', name='proficiencylevel'), nullable=True),
        sa.Column('category', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['profile_id'], ['student_profiles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    
    # careers table
    op.create_table(
        'careers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('category', sa.String(), nullable=True),
        sa.Column('average_salary', sa.String(), nullable=True),
        sa.Column('growth_outlook', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
    )
    
    # career_required_skills table
    op.create_table(
        'career_required_skills',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('career_id', sa.Integer(), nullable=False),
        sa.Column('skill_name', sa.String(), nullable=False),
        sa.Column('proficiency_required', sa.Enum('beginner', 'intermediate', 'advanced', 'expert', name='careerproficiency'), nullable=True),
        sa.Column('importance_weight', sa.Integer(), nullable=False, server_default=sa.text('1')),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['career_id'], ['careers.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    
    # career_recommendations table
    op.create_table(
        'career_recommendations',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('career_id', sa.Integer(), nullable=True),
        sa.Column('match_score', sa.Integer(), nullable=True),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('matching_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('missing_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('ai_provider', sa.String(), nullable=True),
        sa.Column('ai_model', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['career_id'], ['careers.id'], ondelete='SET NULL'),
    )
    
    # skill_gap_analyses table
    op.create_table(
        'skill_gap_analyses',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('career_id', sa.Integer(), nullable=True),
        sa.Column('match_percentage', sa.Integer(), nullable=True),
        sa.Column('existing_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('required_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('missing_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('identified_skills', sa.ARRAY(sa.String()), nullable=True),
        sa.Column('ai_provider', sa.String(), nullable=True),
        sa.Column('ai_model', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['career_id'], ['careers.id'], ondelete='SET NULL'),
    )
    
    # learning_roadmaps table
    op.create_table(
        'learning_roadmaps',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('career_id', sa.Integer(), nullable=True),
        sa.Column('title', sa.String(), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('ai_provider', sa.String(), nullable=True),
        sa.Column('ai_model', sa.String(), nullable=True),
        sa.Column('version', sa.String(), nullable=True, server_default=sa.text('"1.0"')),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['career_id'], ['careers.id'], ondelete='SET NULL'),
    )
    
    # roadmap_versions table
    op.create_table(
        'roadmap_versions',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('roadmap_id', sa.Integer(), nullable=False),
        sa.Column('version_number', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('json_data', sa.JSON(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
    )
    
    # roadmap_phases table
    op.create_table(
        'roadmap_phases',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('roadmap_id', sa.Integer(), nullable=False),
        sa.Column('phase_name', sa.String(), nullable=False),
        sa.Column('phase_order', sa.Integer(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('estimated_duration', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['roadmap_id'], ['learning_roadmaps.id'], ondelete='CASCADE'),
    )
    
    # roadmap_tasks table
    op.create_table(
        'roadmap_tasks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('phase_id', sa.Integer(), nullable=False),
        sa.Column('task_name', sa.String(), nullable=False),
        sa.Column('task_description', sa.Text(), nullable=True),
        sa.Column('skill_focus', sa.String(), nullable=True),
        sa.Column('estimated_duration', sa.String(), nullable=True),
        sa.Column('order_index', sa.Integer(), nullable=False),
        sa.Column('completion_criteria', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['phase_id'], ['roadmap_phases.id'], ondelete='CASCADE'),
    )
    
    # learning_resources table
    op.create_table(
        'learning_resources',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('task_id', sa.Integer(), nullable=True),
        sa.Column('resource_name', sa.String(), nullable=False),
        sa.Column('platform', sa.String(), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('resource_type', sa.String(), nullable=True),
        sa.Column('url', sa.String(), nullable=True),
        sa.Column('estimated_learning_duration', sa.String(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('ai_provider', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
    )
    
    # task_progress table
    op.create_table(
        'task_progress',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('task_id', sa.Integer(), nullable=False),
        sa.Column('status', sa.Enum('completed', 'in_progress', 'not_started', name='taskstatus'), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['task_id'], ['roadmap_tasks.id'], ondelete='CASCADE'),
    )
    
    # Create indexes
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
    op.create_index(op.f('ix_student_profiles_user_id'), 'student_profiles', ['user_id'])
    op.create_index(op.f('ix_student_skills_user_id'), 'student_skills', ['user_id'])
    op.create_index(op.f('ix_careers_name'), 'careers', ['name'], unique=True)
    op.create_index(op.f('ix_career_required_skills_career_id'), 'career_required_skills', ['career_id'])
    op.create_index(op.f('ix_career_recommendations_user_id'), 'career_recommendations', ['user_id'])
    op.create_index(op.f('ix_skill_gap_analyses_user_id'), 'skill_gap_analyses', ['user_id'])
    op.create_index(op.f('ix_learning_roadmaps_user_id'), 'learning_roadmaps', ['user_id'])
    op.create_index(op.f('ix_roadmap_versions_roadmap_id'), 'roadmap_versions', ['roadmap_id'])
    op.create_index(op.f('ix_roadmap_phases_roadmap_id'), 'roadmap_phases', ['roadmap_id'])
    op.create_index(op.f('ix_roadmap_tasks_phase_id'), 'roadmap_tasks', ['phase_id'])
    op.create_index(op.f('ix_learning_resources_task_id'), 'learning_resources', ['task_id'])
    op.create_index(op.f('ix_task_progress_user_id'), 'task_progress', ['user_id'])
    op.create_index(op.f('ix_task_progress_task_id'), 'task_progress', ['task_id'])
    
    # Create triggers for updated_at on student_profiles
    op.execute("""
        CREATE OR REPLACE FUNCTION update_student_profiles_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    op.execute("""
        CREATE TRIGGER update_student_profiles_updated_at_trigger
        BEFORE UPDATE ON student_profiles
        FOR EACH ROW
        EXECUTE FUNCTION update_student_profiles_updated_at();
    """)


def downgrade() -> None:
    """Downgrade schema."""
    
    # Drop triggers and functions first
    op.execute("DROP TRIGGER IF EXISTS update_student_profiles_updated_at_trigger ON student_profiles;")
    op.execute("DROP FUNCTION IF EXISTS update_student_profiles_updated_at()")
    
    # Drop tables in reverse order (due to foreign key dependencies)
    op.drop_table('task_progress')
    op.drop_table('learning_resources')
    op.drop_table('roadmap_tasks')
    op.drop_table('roadmap_phases')
    op.drop_table('roadmap_versions')
    op.drop_table('learning_roadmaps')
    op.drop_table('skill_gap_analyses')
    op.drop_table('career_recommendations')
    op.drop_table('career_required_skills')
    op.drop_table('careers')
    op.drop_table('student_skills')
    op.drop_table('student_profiles')
    op.drop_table('users')
    
    # Drop enum types
    op.execute("DROP TYPE IF EXISTS taskstatus")
    op.execute("DROP TYPE IF EXISTS careerproficiency")
    op.execute("DROP TYPE IF EXISTS proficiencylevel")