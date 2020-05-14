from pathlib import Path
import pytest

from bigquery_etl.query_scheduling.dag import Dag, DagParseException
from bigquery_etl.query_scheduling.task import Task

TEST_DIR = Path(__file__).parent.parent


class TestDag:
    default_args = {
        "owner": "test@example.org",
        "email": ["test@example.org"],
        "depends_on_past": False,
    }

    def test_dag_instantiation(self):
        dag = Dag("bqetl_test_dag", "daily", self.default_args)

        assert dag.name == "bqetl_test_dag"
        assert dag.schedule_interval == "daily"
        assert dag.tasks == []
        assert dag.default_args == self.default_args

    def test_add_tasks(self):
        dag = Dag("bqetl_test_dag", "daily", self.default_args)

        query_file = (
            TEST_DIR
            / "data"
            / "test_sql"
            / "test"
            / "incremental_query_v1"
            / "query.sql"
        )

        tasks = [Task.of_query(query_file), Task.of_query(query_file)]

        assert dag.tasks == []

        dag.add_tasks(tasks)

        assert len(dag.tasks) == 2

    def test_from_dict(self):
        dag = Dag.from_dict(
            {
                "bqetl_test_dag": {
                    "schedule_interval": "daily",
                    "default_args": {
                        "owner": "test@example.com",
                        "email": ["test@example.com"],
                    },
                }
            }
        )

        assert dag.name == "bqetl_test_dag"
        assert dag.schedule_interval == "daily"
        assert dag.default_args.owner == "test@example.com"
        assert dag.default_args.email == ["test@example.com"]
        assert dag.default_args.depends_on_past is False

    def test_from_empty_dict(self):
        with pytest.raises(DagParseException):
            Dag.from_dict({})

    def test_from_dict_multiple_dags(self):
        with pytest.raises(DagParseException):
            Dag.from_dict({"bqetl_test_dag1": {}, "bqetl_test_dag2": {}})

    def test_from_dict_without_scheduling_interval(self):
        with pytest.raises(DagParseException):
            Dag.from_dict({"bqetl_test_dag": {}})

    def test_invalid_dag_name(self):
        with pytest.raises(ValueError):
            Dag("test_dag", "daily", self.default_args)

    def test_schedule_interval_format(self):
        assert Dag("bqetl_test_dag", "daily", self.default_args)
        assert Dag("bqetl_test_dag", "weekly", self.default_args)
        assert Dag("bqetl_test_dag", "once", self.default_args)

        with pytest.raises(ValueError):
            assert Dag("bqetl_test_dag", "never", self.default_args)

        assert Dag("bqetl_test_dag", "* * * * *", self.default_args)
        assert Dag("bqetl_test_dag", "1 * * * *", self.default_args)

        with pytest.raises(TypeError):
            assert Dag("bqetl_test_dag", 323, self.default_args)
