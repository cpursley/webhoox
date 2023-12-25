defmodule Webhoox.Parser.Test do
  use ExUnit.Case
  import Webhoox.Parser

  test "parse_timestamp/1: returns timestamp string" do
    assert parse_timestamp("1544797214") == "1544797214"
    assert parse_timestamp(1_544_797_214) == "1544797214"
    assert parse_timestamp(1_544_797_214.955656) == "1544797214.955656"
    refute parse_timestamp(nil)
  end

  test "parse_email_address/1: returns email address tuple" do
    assert parse_email_address("Bob <bob@mg.example.com>") == {"Bob", "bob@mg.example.com"}
    assert parse_email_address("bob@mg.example.com") == {"", "bob@mg.example.com"}
    refute parse_email_address("invalid email address")
    refute parse_email_address(12_345)
    refute parse_email_address(nil)
  end

  test "parse_email_recipients/1: returns list of email address tuples" do
    assert parse_email_recipients("Bob <bob@mg.example.com>") == [{"Bob", "bob@mg.example.com"}]

    assert parse_email_recipients("Bob <bob@mg.example.com>, Sarah <sarah@mg.example.com>") == [
             {"Bob", "bob@mg.example.com"},
             {"Sarah", "sarah@mg.example.com"}
           ]

    refute parse_email_recipients(nil)
  end
end
