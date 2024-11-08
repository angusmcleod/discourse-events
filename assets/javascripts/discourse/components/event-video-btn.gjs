import Component from "@glimmer/component";
import dIcon from "discourse-common/helpers/d-icon";
import I18n from "I18n";

export default class EventVideoBtn extends Component {
  get label() {
    return I18n.t("topic.event.video.label");
  }

  <template>
    <a
      href={{@video_url}}
      target="_blank"
      role="button"
      class="btn btn-primary btn-event-video"
      rel="noopener noreferrer"
    >
      {{dIcon "video"}}
      <span>{{this.label}}</span>
    </a>
  </template>
}
