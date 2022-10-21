locals {
    idp_uri_denylist_filter = join(" && ", formatlist("$.uri_path != \"%s\"", [
            "/manifest.json",
            "/",
            "rules_of_use",
            "/favicon-32x32.png",
            "/health_check",
            "/apple-touch-icon.png",
            "/es"
    ]))
}

resource "aws_cloudwatch_log_metric_filter" "idp_filtered_uris_success" {
    name = "${var.env_name}-idp-filtered-uris-success"
    pattern = concat("{", local.idp_uri_denylist_filter, " && ($.status = 2* || $.status = 3*)}")
}

resource "aws_cloudwatch_log_metric_filter" "idp_filtered_uris_total" {
    name = "${var.env_name}-idp-filtered-uris-success"
    pattern = concat("{", local.idp_uri_denylist_filter, "}")
}
