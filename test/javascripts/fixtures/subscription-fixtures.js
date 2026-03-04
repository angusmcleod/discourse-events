const features = {
  provider: {
    provider_type: {
      icalendar: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
      google: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
      outlook: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
    },
  },
  source: {
    import_type: {
      import: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
      import_publish: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
      publish: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
    },
    topic_sync: {
      manual: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
      auto: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
    },
    client: {
      discourse_events: {
        none: true,
        community: true,
        business: true,
        enterprise: true,
      },
    },
  },
};

export default {
  product: "enterprise",
  features,
};
