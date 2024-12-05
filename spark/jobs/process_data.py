from pyspark.sql import SparkSession
from delta import *

def create_spark_session():
    return (SparkSession.builder
            .appName("KafkaProcessor")
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
            .getOrCreate())

def process_kafka_stream(spark):
    return (spark.readStream
            .format("kafka")
            .option("kafka.bootstrap.servers", "kafka-service:9092")
            .option("subscribe", "test-events")
            .load()
            .writeStream
            .format("delta")
            .outputMode("append")
            .option("checkpointLocation", "/tmp/delta/checkpoint")
            .start("/tmp/delta/events"))

if __name__ == "__main__":
    spark = create_spark_session()
    process_kafka_stream(spark) 