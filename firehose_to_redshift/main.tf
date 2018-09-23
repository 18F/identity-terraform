resource "aws_kinesis_firehose_delivery_stream" "rs_stream" {
    name = "${var.env_name}-${var.stream_name}"
    destination = "redshift"

    s3_configuration {
        role_arn = "${aws_iam_role.firehose_role.arn}"
        bucket_arn = "${aws_s3_bucket.bucket.arn}"
        buffer_size = 50
        buffer_interval = 120
        compression_format = "GZIP"
    }

    redshift_configuration {
        role_arn = "${aws_iam_role.firehose_role.arn}"
        cluster_jdbcurl = "${var.redshift_jdbc}"
        username = "${var.redshit_user}"
        password = "${var.redshift_password}"
        data_table_name = "${var.redshift_table}"
        copy_options = "${var.copy_options}" 
        data_table_columns = "${var.columns}"
        s3_backup_mode = "Enabled"
        s3_backup_configuration {
            role_arn = "${aws_iam_role.firehose_role.arn}"
            bucket_arn = "${aws_s3_bucket.bucket.arn}"
            buffer_size = 15
        buffer_interval = 300
        compression_format = "GZIP"
        }
    }
}