final: prev:

{
  commitizen = prev.commitizen.overridePythonAttrs (old: {
    pytestFlags = (old.pytestFlags or [ ]) ++ [
      "--deselect=tests/test_cli.py::test_invalid_command[py_3.14-invalidCommand]"
    ];
  });
}
