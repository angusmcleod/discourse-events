import Controller from "@ember/controller";
import { notEmpty } from "@ember/object/computed";
import Message from "../mixins/message";

export default Controller.extend(Message, {
  hasLogs: notEmpty("logs"),
  order: null,
  asc: null,
  view: "log",
});
